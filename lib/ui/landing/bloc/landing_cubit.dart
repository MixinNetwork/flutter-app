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
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../../account/account_key_value.dart';
import '../../../account/account_server.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/crypto_key_value.dart';
import '../../../crypto/signal/signal_protocol.dart';
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

  final StreamController<Tuple2<int, String>> periodicStreamController =
      StreamController<Tuple2<int, String>>();
  StreamSubscription? streamSubscription;
  late signal.ECKeyPair keyPair;

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

      streamSubscription = Stream.periodic(const Duration(milliseconds: 1500),
              (i) => Tuple2(i, rsp.data.deviceId))
          .listen(periodicStreamController.add);
      addSubscription(streamSubscription);
    } catch (error, stack) {
      e('requestAuthUrl failed: $error $stack');
      emit(state.needReload('Failed to request auth: $error'));
    }
  }

  void _initLandingListen() {
    final subscription = periodicStreamController.stream
        .where((event) {
          if (event.item1 < 60) return true;
          streamSubscription?.cancel();
          emit(state.needReload('qrcode display timeout.'));
          return false;
        })
        .map((event) => event.item2)
        .asyncMap((deviceId) async =>
            (await client.provisioningApi.getProvisioning(deviceId))
                .data
                .secret)
        .handleError((e) => null)
        .where((secret) => secret.isNotEmpty)
        .map((secret) {
          streamSubscription?.cancel();
          emit(state.copyWith(
            status: LandingStatus.provisioning,
          ));
          return secret;
        })
        .asyncMap(_verify)
        .handleError((error, stack) {
          emit(state.needReload('Failed to verify: $error'));
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

class LandingMobileCubit extends LandingCubit<void> {
  LandingMobileCubit(
    MultiAuthCubit authCubit,
    Locale locale, {
    required String deviceId,
    required String userAgent,
  }) : super(
          authCubit,
          locale,
          null,
          deviceId: deviceId,
          userAgent: userAgent,
        );
}
