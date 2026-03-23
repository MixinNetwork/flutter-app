import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../account/account_key_value.dart';
import '../../../crypto/crypto_key_value.dart';
import '../../../crypto/signal/signal_protocol.dart';
import '../../../generated/l10n.dart';
import '../../../utils/logger.dart';
import '../../../utils/platform.dart';
import '../../../utils/system/package_info.dart';
import '../../provider/multi_auth_provider.dart';
import 'landing_state.dart';

Client buildLandingClient(
  Locale locale, {
  String? userAgent,
  String? deviceId,
}) => Client(
  dioOptions: BaseOptions(
    headers: {
      'Accept-Language': locale.languageCode,
      'User-Agent': ?userAgent,
      'Mixin-Device-Id': ?deviceId,
    },
  ),
);

class LandingQrCodeNotifier extends Notifier<LandingState> {
  StreamSubscription<void>? _periodicSubscription;

  late final Client client = buildLandingClient(
    PlatformDispatcher.instance.locale,
  );

  @override
  LandingState build() {
    ref.onDispose(() {
      unawaited(_periodicSubscription?.cancel());
    });

    final multiAuth = ref.watch(multiAuthNotifierProvider.notifier);
    final initialState = LandingState(
      status: multiAuth.current != null
          ? LandingStatus.provisioning
          : LandingStatus.init,
    );
    if (multiAuth.current == null) {
      Future<void>.microtask(requestAuthUrl);
    }
    return initialState;
  }

  Future<void> requestAuthUrl() async {
    await _cancelPeriodicSubscription();
    try {
      final rsp = await client.provisioningApi.getProvisioningId(
        Platform.operatingSystem,
      );
      final keyPair = signal.Curve.generateKeyPair();
      final pubKey = Uri.encodeComponent(
        base64Encode(keyPair.publicKey.serialize()),
      );

      state = state.copyWith(
        authUrl: 'mixin://device/auth?id=${rsp.data.deviceId}&pub_key=$pubKey',
        status: LandingStatus.ready,
      );

      _periodicSubscription =
          Stream.periodic(const Duration(seconds: 1), (i) => i)
              .asyncMap(
                (event) => _checkLanding(event, rsp.data.deviceId, keyPair),
              )
              .listen((event) {});
    } catch (error, stack) {
      e('requestAuthUrl failed: $error $stack');
      state = state.needReload('Failed to request auth: $error');
    }
  }

  Future<void> _cancelPeriodicSubscription() async {
    final subscription = _periodicSubscription;
    _periodicSubscription = null;
    await subscription?.cancel();
  }

  Future<void> _checkLanding(
    int count,
    String deviceId,
    signal.ECKeyPair keyPair,
  ) async {
    if (_periodicSubscription == null) return;

    if (count > 60) {
      await _cancelPeriodicSubscription();
      state = state.needReload(Localization.current.qrCodeExpiredDesc);
      return;
    }

    String secret;
    try {
      secret = (await client.provisioningApi.getProvisioning(
        deviceId,
      )).data.secret;
    } catch (_) {
      return;
    }
    if (secret.isEmpty) return;

    await _cancelPeriodicSubscription();
    state = state.copyWith(status: LandingStatus.provisioning);

    try {
      final (account, privateKey) = await _verify(secret, keyPair);
      ref
          .read(multiAuthNotifierProvider.notifier)
          .signIn(
            AuthState(account: account, privateKey: privateKey),
          );
    } catch (error, stack) {
      state = state.needReload('Failed to verify: $error');
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
}
