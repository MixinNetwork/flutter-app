import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as signal;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/resources.dart';
import '../../crypto/signal/signal_protocol.dart';
import '../../generated/l10n.dart';
import '../../utils/extension/extension.dart';
import '../../utils/mixin_api_client.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../../widgets/qr_code.dart';
import '../provider/account/multi_auth_provider.dart';
import 'landing.dart';
import 'landing_initialize.dart';

final _qrCodeLoginProvider =
    StateNotifierProvider.autoDispose<_QrCodeLoginNotifier, LandingState>(
  _QrCodeLoginNotifier.new,
);

class LandingQrCodeWidget extends HookConsumerWidget {
  const LandingQrCodeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(_qrCodeLoginProvider.select((value) => value.status));
    final Widget child;
    if (status == LandingStatus.provisioning) {
      child = Center(
        child: LoadingWidget(
          title: context.l10n.loading,
          message: context.l10n.chatHintE2e,
        ),
      );
    } else {
      child = Stack(
        fit: StackFit.expand,
        children: [
          const Column(
            children: [
              Spacer(),
              _QrCode(),
              Spacer(),
            ],
          ),
          if (kPlatformIsMobile)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: LandingModeSwitchButton(),
              ),
            ),
        ],
      );
    }
    return child;
  }
}

class _QrCode extends HookConsumerWidget {
  const _QrCode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url =
        ref.watch(_qrCodeLoginProvider.select((value) => value.authUrl));

    final visible = ref.watch(_qrCodeLoginProvider
        .select((value) => value.status == LandingStatus.needReload));

    final errorMessage =
        ref.watch(_qrCodeLoginProvider.select((value) => value.errorMessage));

    Widget? qrCode;

    if (url != null) {
      qrCode = QrCode(
        image: const AssetImage(Resources.assetsImagesLogoPng),
        data: url,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(11)),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: SizedBox.fromSize(
            size: const Size.square(160),
            child: Stack(
              fit: StackFit.expand,
              children: [
                qrCode ?? const SizedBox(),
                Visibility(
                  visible: visible,
                  child: _Retry(
                    errorMessage: errorMessage,
                    onTap: () => ref
                        .read(_qrCodeLoginProvider.notifier)
                        .requestAuthUrl(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.loginByQrcode,
          style: TextStyle(
            fontSize: 16,
            color: context.theme.text,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 14,
              color: context.dynamicColor(
                const Color.fromRGBO(187, 190, 195, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
              ),
            ),
            textAlign: TextAlign.left,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. ${context.l10n.loginByQrcodeTips1}'),
                const SizedBox(height: 4),
                Text('2. ${context.l10n.loginByQrcodeTips2}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({
    required this.onTap,
    this.errorMessage,
  });

  final VoidCallback onTap;

  final String? errorMessage;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.86),
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Tooltip(
            message: errorMessage ?? '',
            excludeFromSemantics: true,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    Resources.assetsImagesIcRetrySvg,
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      context.l10n.clickToReloadQrcode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

enum LandingStatus {
  needReload,
  provisioning,
  ready,
}

class LandingState extends Equatable {
  const LandingState({
    this.authUrl,
    required this.status,
    this.errorMessage,
  });

  final String? authUrl;
  final LandingStatus status;

  final String? errorMessage;

  @override
  List<Object?> get props => [authUrl, status, errorMessage];

  LandingState needReload(String errorMessage) => LandingState(
        status: LandingStatus.needReload,
        errorMessage: errorMessage,
        authUrl: authUrl,
      );

  LandingState copyWith({
    String? authUrl,
    LandingStatus? status,
  }) =>
      LandingState(
        authUrl: authUrl ?? this.authUrl,
        status: status ?? this.status,
      );
}

class _QrCodeLoginNotifier extends StateNotifier<LandingState> {
  _QrCodeLoginNotifier(this.ref)
      : multiAuth = ref.read(multiAuthStateNotifierProvider.notifier),
        super(const LandingState(status: LandingStatus.provisioning)) {
    requestAuthUrl();
  }

  final MultiAuthStateNotifier multiAuth;
  final client = createLandingClient();
  final Ref ref;

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
      final rsp = await client.provisioningApi
          .getProvisioningId(Platform.operatingSystem);
      final keyPair = signal.Curve.generateKeyPair();
      final pubKey =
          Uri.encodeComponent(base64Encode(keyPair.publicKey.serialize()));

      state = state.copyWith(
        authUrl: 'mixin://device/auth?id=${rsp.data.deviceId}&pub_key=$pubKey',
        status: LandingStatus.ready,
      );

      _periodicSubscription = Stream.periodic(
        const Duration(milliseconds: 1500),
        (i) => i,
      )
          .asyncBufferMap(
              (event) => _checkLanding(event.last, rsp.data.deviceId, keyPair))
          .listen((event) {});
    } catch (error, stack) {
      e('requestAuthUrl failed: $error $stack');
      state = state.needReload('Failed to request auth: $error');
    }
  }

  Future<void> _checkLanding(
    int count,
    String deviceId,
    signal.ECKeyPair keyPair,
  ) async {
    if (_periodicSubscription == null) return;

    if (count > 40) {
      _cancelPeriodicSubscription();
      state = state.needReload(Localization.current.qrCodeExpiredDesc);
      return;
    }

    String secret;
    try {
      secret =
          (await client.provisioningApi.getProvisioning(deviceId)).data.secret;
    } catch (e) {
      return;
    }
    if (secret.isEmpty) return;

    _cancelPeriodicSubscription();
    state = state.copyWith(status: LandingStatus.provisioning);

    try {
      final (acount, privateKey) = await _verify(secret, keyPair);
      multiAuth.signIn(AuthState(account: acount, privateKey: privateKey));
    } catch (error, stack) {
      state = state.needReload('Failed to verify: $error');
      e('_verify: $error $stack');
    }
  }

  FutureOr<(Account, String)> _verify(
      String secret, signal.ECKeyPair keyPair) async {
    final result =
        signal.decrypt(base64Encode(keyPair.privateKey.serialize()), secret);
    final msg =
        json.decode(String.fromCharCodes(result)) as Map<String, dynamic>;

    final edKeyPair = ed.generateKey();
    final private = base64.decode(msg['identity_key_private'] as String);
    final registrationId = signal.generateRegistrationId(false);

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

    final identityNumber = rsp.data.identityNumber;
    await SignalProtocol.initSignal(identityNumber, registrationId, private);
    ref.read(landingIdentityNumberProvider.notifier).state = identityNumber;

    final privateKey = base64Encode(edKeyPair.privateKey.bytes);

    final hiveKeyValues = await ref.read(landingKeyValuesProvider.future);
    if (hiveKeyValues == null) {
      throw Exception('can not init hiveKeyValues');
    }
    hiveKeyValues.accountKeyValue.primarySessionId = sessionId;
    hiveKeyValues.cryptoKeyValue.localRegistrationId = registrationId;

    return (
      rsp.data,
      privateKey,
    );
  }

  @override
  Future<void> dispose() async {
    await _periodicSubscription?.cancel();
    await periodicStreamController.close();
    super.dispose();
  }
}
