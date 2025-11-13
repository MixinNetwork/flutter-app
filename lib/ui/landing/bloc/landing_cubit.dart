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

class LandingQrCodeCubit extends LandingCubit<LandingState> {
  LandingQrCodeCubit(
    MultiAuthStateNotifier multiAuthChangeNotifier,
    Locale locale,
  ) : super(
        multiAuthChangeNotifier,
        locale,
        LandingState(
          status: multiAuthChangeNotifier.current != null
              ? LandingStatus.provisioning
              : LandingStatus.init,
        ),
      ) {
    if (multiAuthChangeNotifier.current != null) return;
    requestAuthUrl();
  }

  final StreamController<(int, String, signal.ECKeyPair)>
  periodicStreamController =
      StreamController<(int, String, signal.ECKeyPair)>();

  StreamSubscription? _periodicSubscription;

  void _cancelPeriodicSubscription() {
    final periodicSubscription = _periodicSubscription;
    _periodicSubscription = null;
    unawaited(periodicSubscription?.cancel());
  }

  Future<void> requestAuthUrl() async {
    _cancelPeriodicSubscription();
    try {
      final rsp = await client.provisioningApi.getProvisioningId(
        Platform.operatingSystem,
      );
      final keyPair = signal.Curve.generateKeyPair();
      final pubKey = Uri.encodeComponent(
        base64Encode(keyPair.publicKey.serialize()),
      );

      emit(
        state.copyWith(
          authUrl:
              'mixin://device/auth?id=${rsp.data.deviceId}&pub_key=$pubKey',
          status: LandingStatus.ready,
        ),
      );

      _periodicSubscription =
          Stream.periodic(
                const Duration(milliseconds: 1500),
                (i) => i,
              )
              .asyncBufferMap(
                (event) =>
                    _checkLanding(event.last, rsp.data.deviceId, keyPair),
              )
              .listen((event) {});
    } catch (error, stack) {
      e('requestAuthUrl failed: $error $stack');
      emit(state.needReload('Failed to request auth: $error'));
    }
  }

  Future<void> _checkLanding(
    int count,
    String deviceId,
    signal.ECKeyPair keyPair,
  ) async {
    if (_periodicSubscription == null) return;

    if (count > 60) {
      _cancelPeriodicSubscription();
      emit(state.needReload(Localization.current.qrCodeExpiredDesc));
      return;
    }

    String secret;
    try {
      secret = (await client.provisioningApi.getProvisioning(
        deviceId,
      )).data.secret;
    } catch (e) {
      return;
    }
    if (secret.isEmpty) return;

    _cancelPeriodicSubscription();
    emit(state.copyWith(status: LandingStatus.provisioning));

    try {
      final (acount, privateKey) = await _verify(secret, keyPair);
      multiAuthChangeNotifier.signIn(
        AuthState(account: acount, privateKey: privateKey),
      );
    } catch (error, stack) {
      emit(state.needReload('Failed to verify: $error'));
      e('_verify: $error $stack');
    }
  }

  FutureOr<(Account, String)> _verify(
    String secret,
    signal.ECKeyPair keyPair,
  ) async {
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
    await periodicStreamController.close();
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
