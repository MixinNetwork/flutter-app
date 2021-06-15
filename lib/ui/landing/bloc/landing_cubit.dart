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
import 'package:package_info/package_info.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../../account/account_key_value.dart';
import '../../../bloc/subscribe_mixin.dart';
import '../../../crypto/crypto_key_value.dart';
import '../../../crypto/signal/signal_protocol.dart';
import '../../../utils/logger.dart';
import '../../home/bloc/multi_auth_cubit.dart';

part 'landing_state.dart';

class LandingCubit extends Cubit<LandingState> with SubscribeMixin {
  LandingCubit(this.authCubit, Locale locale)
      : super(LandingState(
          status: authCubit.state.current != null
              ? LandingStatus.provisioning
              : LandingStatus.init,
        )) {
    client = Client(
      dioOptions: BaseOptions(
        headers: {
          'Accept-Language': locale.languageCode,
        },
      ),
    );
    _initLandingListen();
    if (authCubit.state.current != null) return;
    requestAuthUrl();
  }

  final MultiAuthCubit authCubit;
  final StreamController<int> periodicStreamController =
      StreamController<int>();
  late Client client;
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
    } catch (_) {
      emit(state.copyWith(
        status: LandingStatus.needReload,
      ));
    }
  }

  void _initLandingListen() {
    final subscription = periodicStreamController.stream
        .doOnData((event) {
          if (event < 60) return;
          streamSubscription?.cancel();
          emit(state.copyWith(
            status: LandingStatus.needReload,
          ));
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
        .handleError((_) => null)
        .doOnData((auth) {
          if (auth == null) {
            streamSubscription?.cancel();
            emit(state.copyWith(
              status: LandingStatus.needReload,
            ));
          }
        })
        .where((auth) => auth != null)
        .cast<Tuple2<Account, String>>()
        .listen((auth) => authCubit.signIn(
              AuthState(
                account: auth.item1,
                privateKey: auth.item2,
              ),
            ));
    addSubscription(subscription);
  }

  FutureOr<Tuple2<Account, String>?> _verify(secret) async {
    try {
      final result =
          signal.decrypt(base64Encode(keyPair.privateKey.serialize()), secret);
      final msg = json.decode(String.fromCharCodes(result));

      final edKeyPair = ed.generateKey();

      await CryptoKeyValue.instance.init();
      // ignore: avoid_dynamic_calls
      final private = base64.decode(msg['identity_key_private']);
      await SignalProtocol.initSignal(private);
      final registrationId = CryptoKeyValue.instance.localRegistrationId;

      await AccountKeyValue.instance.init();
      // ignore: avoid_dynamic_calls
      final sessionId = msg['session_id'];
      AccountKeyValue.instance.primarySessionId = sessionId;
      String? appVersion;
      if(Platform.isMacOS) {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}(${info.buildNumber})';
      }
      final rsp = await client.provisioningApi.verifyProvisioning(
        ProvisioningRequest(
          // ignore: avoid_dynamic_calls
          code: msg['provisioning_code'],
          // ignore: avoid_dynamic_calls
          userId: msg['user_id'],
          sessionId: sessionId,
          platform: 'Desktop',
          purpose: 'SESSION',
          sessionSecret: base64Encode(edKeyPair.publicKey!.bytes),
          appVersion: appVersion ?? '0.0.1',
          registrationId: registrationId,
          platformVersion: 'OS X 10.15.6',
        ),
      );

      final privateKey = base64Encode(edKeyPair.privateKey!.bytes);

      return Tuple2(
        rsp.data,
        privateKey,
      );
    } catch (err, s) {
      e('$err $s');
      return null;
    }
  }

  @override
  Future<void> close() async {
    await streamSubscription?.cancel();
    await periodicStreamController.close();
    await super.close();
  }
}
