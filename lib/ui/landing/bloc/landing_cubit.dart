import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../../account/account_key_value.dart';
import '../../../account/account_server.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/crypto_key_value.dart';
import '../../../crypto/signal/signal_protocol.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../../utils/system/package_info.dart';
import '../../home/bloc/multi_auth_cubit.dart';
import 'landing_state.dart';

class LandingCubit<T> extends Cubit<T> {
  LandingCubit(
    this.authCubit,
    Locale locale,
    T initialState, {
    String? userAgent,
    String? deviceId,
  })  : client = Client(
          dioOptions: BaseOptions(
            headers: {
              'Accept-Language': locale.languageCode,
              if (userAgent != null) 'User-Agent': userAgent,
              if (deviceId != null) 'Mixin-Device-Id': deviceId,
            },
          ),
        ),
        super(initialState);
  final Client client;
  final MultiAuthCubit authCubit;
}

class LandingQrCodeCubit extends LandingCubit<LandingState>
    with SubscribeMixin {
  LandingQrCodeCubit(MultiAuthCubit authCubit, Locale locale)
      : super(
          authCubit,
          locale,
          LandingState(
            status: authCubit.state.current != null
                ? LandingStatus.provisioning
                : LandingStatus.init,
            errorMessage: lastInitErrorMessage,
          ),
        ) {
    _initLandingListen();
    if (authCubit.state.current != null) return;
    requestAuthUrl();
  }

  final StreamController<int> periodicStreamController =
      StreamController<int>();
  StreamSubscription<int>? streamSubscription;
  late signal.ECKeyPair keyPair;
  String? deviceId;

  Future<void> requestAuthUrl() async {
    await streamSubscription?.cancel();
    try {
      final rsp = await client.provisioningApi
          .getProvisioningId(Platform.operatingSystem);
      keyPair = signal.Curve.generateKeyPair();
      final pubKey =
          Uri.encodeComponent(base64Encode(keyPair.publicKey.serialize()));

      emit(state.copyWith(
        authUrl: 'mixin://device/auth?id=${rsp.data.deviceId}&pub_key=$pubKey',
        status: LandingStatus.ready,
      ));

      deviceId = rsp.data.deviceId;
      streamSubscription = Stream.periodic(const Duration(seconds: 1), (i) => i)
          .listen(periodicStreamController.add);
      addSubscription(streamSubscription);
    } catch (error, stack) {
      e('requestAuthUrl failed: $error $stack');
      emit(state.needReload('Failed to request auth: $error'));
    }
  }

  void _initLandingListen() {
    final subscription = periodicStreamController.stream
        .doOnData((event) {
          if (event < 60) return;
          streamSubscription?.cancel();
          emit(state.needReload('qrcode display timeout.'));
        })
        .where((_) => deviceId != null)
        .asyncMap((event) async =>
            (await client.provisioningApi.getProvisioning(deviceId!))
                .data
                .secret)
        .handleError((e) => null)
        .where((secret) => secret.isNotEmpty == true)
        .doOnData((secret) {
          streamSubscription?.cancel();
          emit(state.copyWith(
            status: LandingStatus.provisioning,
          ));
        })
        .asyncMap(_verify)
        .doOnError((error, stacktrace) {
          emit(state.needReload('Failed to verify: $error'));
        })
        .handleError((error, stack) {
          e('_verify: $error $stack');
          return null;
        })
        .whereNotNull()
        .listen((auth) => authCubit.signIn(
              AuthState(
                account: auth.item1,
                privateKey: auth.item2,
              ),
            ));
    addSubscription(subscription);
  }

  FutureOr<Tuple2<Account, String>?> _verify(String secret) async {
    final result =
        signal.decrypt(base64Encode(keyPair.privateKey.serialize()), secret);
    final msg =
        json.decode(String.fromCharCodes(result)) as Map<String, dynamic>;

    final edKeyPair = ed.generateKey();

    await CryptoKeyValue.instance.init();
    // ignore: avoid_dynamic_calls
    final private = base64.decode(msg['identity_key_private'] as String);
    await SignalProtocol.initSignal(private);
    final registrationId = CryptoKeyValue.instance.localRegistrationId;

    await AccountKeyValue.instance.init();
    final sessionId = msg['session_id'] as String;
    AccountKeyValue.instance.primarySessionId = sessionId;
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

    return Tuple2(
      rsp.data,
      privateKey,
    );
  }

  @override
  Future<void> close() async {
    await streamSubscription?.cancel();
    await periodicStreamController.close();
    await super.close();
  }
}

enum MobileLoginStatus {
  initial,
  error,
}

class MobileLoginState extends Equatable {
  const MobileLoginState({
    this.status = MobileLoginStatus.initial,
    this.hasVerificationCode = false,
    this.errorMessage = '',
  });

  final MobileLoginStatus status;

  final String errorMessage;

  final bool hasVerificationCode;

  MobileLoginState copyWith({
    MobileLoginStatus? status,
    String? errorMessage,
    bool? hasVerificationCode,
  }) =>
      MobileLoginState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        hasVerificationCode: hasVerificationCode ?? this.hasVerificationCode,
      );

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        hasVerificationCode,
      ];
}

class LandingMobileCubit extends LandingCubit<MobileLoginState> {
  LandingMobileCubit(
    MultiAuthCubit authCubit,
    Locale locale, {
    required String deviceId,
    required String userAgent,
  }) : super(
          authCubit,
          locale,
          const MobileLoginState(),
          deviceId: deviceId,
          userAgent: userAgent,
        );

  VerificationResponse? verificationResponse;

  void onVerified(String phoneNumber, VerificationResponse response) {
    verificationResponse = response;
    emit(state.copyWith(
      hasVerificationCode: true,
    ));
  }

  Future<void> login(String code) async {
    final id = verificationResponse?.id;
    if (id == null) {
      return;
    }
    await CryptoKeyValue.instance.init();
    await AccountKeyValue.instance.init();

    await SignalProtocol.initSignal(null);

    final registrationId = CryptoKeyValue.instance.localRegistrationId;
    final sessionKey = ed.generateKey();
    final sessionSecret = base64Encode(sessionKey.publicKey.bytes);

    final packageInfo = await getPackageInfo();
    final platformVersion = await getPlatformVersion();

    final accountRequest = AccountRequest(
      code: code,
      registrationId: registrationId,
      purpose: VerificationPurpose.session,
      // FIXME platform name
      platform: 'Android',
      platformVersion: platformVersion,
      appVersion: packageInfo.version,
      // FIXME package name
      packageName: 'one.mixin.messenger',
      sessionSecret: sessionSecret,
      // TODO pin
      pin: '',
    );
    try {
      final response = await client.accountApi.create(id, accountRequest);
      final privateKey = base64Encode(sessionKey.privateKey.bytes);
      authCubit.signIn(
        AuthState(account: response.data, privateKey: privateKey),
      );
    } catch (error) {
      e('login account error: $error');
      emit(state.copyWith(
        status: MobileLoginStatus.error,
        errorMessage: e.toString(),
      ));
      return;
    }
  }
}
