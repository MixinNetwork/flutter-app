import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../account/account_key_value.dart';
import '../../../crypto/crypto_key_value.dart';
import '../../../crypto/signal/signal_protocol.dart';
import '../../../generated/l10n.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../../utils/system/package_info.dart';
import '../../provider/multi_auth_provider.dart';
import 'landing_state.dart';

class LandingCubit<T> extends Cubit<T> {
  LandingCubit(
    this.multiAuthChangeNotifier,
    Locale locale,
    T initialState, {
    String? userAgent,
    String? deviceId,
  }) : client = Client(
         dioOptions: BaseOptions(
           headers: {
             'Accept-Language': locale.languageCode,
             'User-Agent': ?userAgent,
             'Mixin-Device-Id': ?deviceId,
           },
         ),
       ),
       super(initialState);
  final Client client;
  final MultiAuthStateNotifier multiAuthChangeNotifier;
}

typedef ProvisioningIdLoader = Future<MixinResponse<ProvisioningId>> Function();
typedef ProvisioningLoader =
    Future<MixinResponse<Provisioning>> Function(String deviceId);
typedef ProvisioningVerifier =
    FutureOr<(Account, String)> Function(
      String secret,
      signal.ECKeyPair keyPair,
    );

class LandingQrCodeCubit extends LandingCubit<LandingState> {
  LandingQrCodeCubit(
    MultiAuthStateNotifier multiAuthChangeNotifier,
    Locale locale, {
    this.autoStart = true,
    ProvisioningIdLoader? provisioningIdLoader,
    ProvisioningLoader? provisioningLoader,
    ProvisioningVerifier? provisioningVerifier,
    Stream<int> Function()? pollingStreamFactory,
    this.expirationTickLimit = 60,
    this.pollingFailureLimit = 3,
    String Function()? expiredMessageBuilder,
  }) : super(
         multiAuthChangeNotifier,
         locale,
         LandingState(
           status: multiAuthChangeNotifier.current != null
               ? LandingStatus.provisioning
               : LandingStatus.init,
         ),
       ) {
    _provisioningIdLoader =
        provisioningIdLoader ??
        (() => client.provisioningApi.getProvisioningId(
          Platform.operatingSystem,
        ));
    _provisioningLoader =
        provisioningLoader ??
        ((deviceId) => client.provisioningApi.getProvisioning(deviceId));
    _provisioningVerifier = provisioningVerifier;
    _pollingStreamFactory =
        pollingStreamFactory ??
        (() => Stream.periodic(const Duration(seconds: 1), (i) => i));
    _expiredMessageBuilder =
        expiredMessageBuilder ?? (() => Localization.current.qrCodeExpiredDesc);
    if (!autoStart || multiAuthChangeNotifier.current != null) return;
    requestAuthUrl();
  }

  final bool autoStart;
  late final ProvisioningIdLoader _provisioningIdLoader;
  late final ProvisioningLoader _provisioningLoader;
  late final ProvisioningVerifier? _provisioningVerifier;
  late final Stream<int> Function() _pollingStreamFactory;
  late final String Function() _expiredMessageBuilder;
  final int expirationTickLimit;
  final int pollingFailureLimit;

  StreamSubscription? _periodicSubscription;
  int _requestVersion = 0;
  int _pollingFailureCount = 0;

  void _cancelPeriodicSubscription() {
    final periodicSubscription = _periodicSubscription;
    _periodicSubscription = null;
    unawaited(periodicSubscription?.cancel());
  }

  Future<void> requestAuthUrl({bool isAutoRefresh = false}) async {
    _cancelPeriodicSubscription();
    final requestVersion = ++_requestVersion;
    _pollingFailureCount = 0;
    if (state.authUrl == null) {
      emit(
        state.copyWith(
          status: LandingStatus.init,
          clearErrorMessage: true,
        ),
      );
    } else if (state.status == LandingStatus.needReload) {
      emit(
        state.copyWith(
          status: LandingStatus.ready,
          clearErrorMessage: true,
        ),
      );
    }
    try {
      final rsp = await _provisioningIdLoader();
      if (requestVersion != _requestVersion) return;
      if (isAutoRefresh) {
        i('landing qr auto refresh succeeded');
      }

      final keyPair = signal.Curve.generateKeyPair();
      final pubKey = Uri.encodeComponent(
        base64Encode(keyPair.publicKey.serialize()),
      );

      emit(
        state.copyWith(
          authUrl:
              'mixin://device/auth?id=${rsp.data.deviceId}&pub_key=$pubKey',
          status: LandingStatus.ready,
          clearErrorMessage: true,
        ),
      );

      _periodicSubscription = _pollingStreamFactory()
          .asyncBufferMap(
            (event) => _checkLanding(
              requestVersion,
              event.last,
              rsp.data.deviceId,
              keyPair,
            ),
          )
          .listen((event) {});
    } catch (error, stack) {
      if (requestVersion != _requestVersion) return;
      e('requestAuthUrl failed: $error $stack');
      emit(
        state.needReload(
          isAutoRefresh
              ? 'Failed to refresh QR code: $error'
              : 'Failed to request auth: $error',
        ),
      );
    }
  }

  Future<void> _checkLanding(
    int requestVersion,
    int count,
    String deviceId,
    signal.ECKeyPair keyPair,
  ) async {
    if (_periodicSubscription == null || requestVersion != _requestVersion) {
      return;
    }

    if (count > expirationTickLimit) {
      _cancelPeriodicSubscription();
      i('landing qr expired, auto refreshing');
      unawaited(requestAuthUrl(isAutoRefresh: true));
      return;
    }

    String secret;
    try {
      secret = (await _provisioningLoader(deviceId)).data.secret;
    } catch (e) {
      if (requestVersion != _requestVersion) return;
      _pollingFailureCount += 1;
      if (_pollingFailureCount >= pollingFailureLimit) {
        _cancelPeriodicSubscription();
        w('landing qr polling failed, entering retry state');
        emit(state.needReload(_expiredMessageBuilder()));
      }
      return;
    }
    _pollingFailureCount = 0;
    if (secret.isEmpty) return;

    _cancelPeriodicSubscription();
    if (requestVersion != _requestVersion) return;
    emit(state.copyWith(status: LandingStatus.provisioning));

    try {
      final (acount, privateKey) = await _verify(secret, keyPair);
      if (requestVersion != _requestVersion) return;
      multiAuthChangeNotifier.signIn(
        AuthState(account: acount, privateKey: privateKey),
      );
    } catch (error, stack) {
      if (requestVersion != _requestVersion) return;
      emit(state.needReload('Failed to verify: $error'));
      e('_verify: $error $stack');
    }
  }

  FutureOr<(Account, String)> _verify(
    String secret,
    signal.ECKeyPair keyPair,
  ) async {
    final provisioningVerifier = _provisioningVerifier;
    if (provisioningVerifier != null) {
      return provisioningVerifier(secret, keyPair);
    }

    final result = signal.decrypt(
      base64Encode(keyPair.privateKey.serialize()),
      secret,
    );
    final msg =
        json.decode(String.fromCharCodes(result)) as Map<String, dynamic>;

    final edKeyPair = ed.generateKey();
    final private = base64.decode(msg['identity_key_private'] as String);
    final registrationId = await SignalProtocol.initSignal(private);

    final sessionId = msg['session_id'] as String;
    final info = await getPackageInfo();
    final appVersion = '${info.version}(${info.buildNumber})';
    final platformVersion = await getPlatformVersion();
    final rsp = await client.provisioningApi.verifyProvisioning(
      ProvisioningRequest(
        code: msg['provisioning_code'] as String,
        userId: msg['user_id'] as String,
        sessionId: sessionId,
        purpose: 'SESSION',
        sessionSecret: base64Encode(edKeyPair.publicKey.bytes),
        appVersion: appVersion,
        registrationId: registrationId,
        platform: 'Desktop',
        platformVersion: platformVersion,
      ),
    );

    final privateKey = base64Encode(edKeyPair.privateKey.bytes);

    await AccountKeyValue.instance.init(rsp.data.identityNumber);
    AccountKeyValue.instance.primarySessionId = sessionId;
    await CryptoKeyValue.instance.init(rsp.data.identityNumber);
    CryptoKeyValue.instance.localRegistrationId = registrationId;

    return (rsp.data, privateKey);
  }

  @override
  Future<void> close() async {
    await _periodicSubscription?.cancel();
    await super.close();
  }
}

class LandingMobileCubit extends LandingCubit<void> {
  LandingMobileCubit(
    MultiAuthStateNotifier multiAuthChangeNotifier,
    Locale locale, {
    required String deviceId,
    required String userAgent,
  }) : super(
         multiAuthChangeNotifier,
         locale,
         null,
         deviceId: deviceId,
         userAgent: userAgent,
       );
}
