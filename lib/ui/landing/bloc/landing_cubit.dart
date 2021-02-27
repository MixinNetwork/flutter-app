import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

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
          Uri.encodeComponent(base64.encode(keyPair.publicKey.serialize()));

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
        .asyncMap((event) async {
          final rsp = await client.provisioningApi.getProvisioning(deviceId);
          return rsp.data?.secret;
        })
        .handleError((_) => null)
        .where((secret) => secret?.isNotEmpty == true)
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
    final result =
        signal.decrypt(base64.encode(keyPair.privateKey.serialize()), secret);
    final msg = json.decode(String.fromCharCodes(result));

    final edKeyPair = ed.generateKey();
    final registrationId = signal.KeyHelper.generateRegistrationId(false);

    final rsp = await client.provisioningApi.verifyProvisioning(
      ProvisioningRequest(
        code: msg['provisioning_code'],
        userId: msg['user_id'],
        sessionId: msg['session_id'],
        platform: 'Desktop',
        purpose: 'SESSION',
        sessionSecret: base64.encode(edKeyPair.publicKey.bytes),
        appVersion: '0.0.1',
        registrationId: registrationId,
        platformVersion: 'OS X 10.15.6',
      ),
    );

    if (rsp.data != null) {
      final privateKey = base64.encode(edKeyPair.privateKey.bytes);

      return Tuple2(
        rsp.data,
        privateKey,
      );
    }
    return null;
  }

  @override
  Future<void> close() async {
    await streamSubscription?.cancel();
    await periodicStreamController.close();
    await super.close();
  }
}
