import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../account/account_key_value.dart';
import '../../crypto/signal/signal_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hive_key_values.dart';
import '../../utils/hook.dart';
import '../../utils/mixin_api_client.dart';
import '../../utils/platform.dart';
import '../../utils/system/package_info.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../provider/account_server_provider.dart';
import '../provider/multi_auth_provider.dart';
import '../provider/ui_context_providers.dart';
import '../setting/log_page.dart';
import 'controllers/landing_controller.dart';
import 'controllers/landing_state.dart';
import 'landing_mobile.dart';
import 'landing_qrcode.dart';

enum LandingMode { qrcode, mobile }

final landingModeControllerProvider =
    NotifierProvider.autoDispose<LandingModeController, LandingMode>(
      LandingModeController.new,
    );

final landingQrCodeNotifierProvider =
    NotifierProvider.autoDispose<LandingQrCodeNotifier, LandingState>(
      LandingQrCodeNotifier.new,
    );

typedef LandingMobilePlatformInfo = ({String userAgent, String deviceId});

final landingMobilePlatformInfoProvider =
    FutureProvider.autoDispose<LandingMobilePlatformInfo>((ref) async {
      final userAgent = await generateUserAgent();
      final deviceId = await getDeviceId();
      return (userAgent: userAgent ?? '', deviceId: deviceId);
    });

final landingMobileClientProvider = FutureProvider.autoDispose<Client>((
  ref,
) async {
  final platformInfo = await ref.watch(
    landingMobilePlatformInfoProvider.future,
  );
  return buildLandingClient(
    PlatformDispatcher.instance.locale,
    userAgent: platformInfo.userAgent,
    deviceId: platformInfo.deviceId,
  );
});

class LandingModeController extends Notifier<LandingMode> {
  @override
  LandingMode build() => LandingMode.qrcode;

  void changeMode(LandingMode mode) => state = mode;
}

class LandingPage extends HookConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      accountServerProvider,
      (previous, next) {
        if (!next.hasError) return;
        e(
          'accountServerProvider error changed: '
          'previousError=${previous?.error} '
          'nextError=${next.error} '
          'nextStackTrace=${next.stackTrace}',
        );
      },
    );
    final accountServerHasError = ref.watch(
      accountServerProvider.select((value) => value.hasError),
    );
    final mode = ref.watch(landingModeControllerProvider);

    Widget child;
    switch (mode) {
      case LandingMode.qrcode:
        child = const LandingQrCodeWidget();
      case LandingMode.mobile:
        child = const LoginWithMobileWidget();
    }
    if (accountServerHasError) {
      child = const _LoginFailed();
    }
    return LandingScaffold(child: child);
  }
}

class _LoginFailed extends HookConsumerWidget {
  const _LoginFailed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final accountServerError = ref.watch(accountServerProvider);

    final errorText = 'Error: ${accountServerError.error}';
    final stackTraceText = 'StackTrace: ${accountServerError.stackTrace}';

    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 30, right: 48, left: 48),
      child: Column(
        children: [
          Text(
            l10n.unknowError,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.red,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              child: SelectionArea(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.sidebarSelected,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(errorText),
                          Text(stackTraceText),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 42),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MixinButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 14,
                ),
                backgroundTransparent: true,
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '$errorText\n$stackTraceText'),
                  );
                  showToastSuccessful();
                },
                child: Text(l10n.copy),
              ),
              MixinButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 14,
                ),
                onTap: () async {
                  final authState = ref.read(authProvider);
                  if (authState == null) return;

                  try {
                    await createClient(
                      userId: authState.account.userId,
                      sessionId: authState.account.sessionId,
                      privateKey: authState.privateKey,
                      loginByPhoneNumber:
                          AccountKeyValue.instance.primarySessionId == null,
                    ).accountApi.logout(
                      LogoutRequest(authState.account.sessionId),
                    );
                  } catch (err, stacktrace) {
                    e('logout error: $err $stacktrace');
                  }
                  await clearKeyValues();
                  await SignalDatabase.get.clear();
                  ref.read(multiAuthNotifierProvider.notifier).signOut();
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LandingScaffold extends HookConsumerWidget {
  const LandingScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final backgroundColor = ref.watch(
      dynamicColorProvider((
        color: const Color(0xFFE5E5E5),
        darkColor: const Color.fromRGBO(35, 39, 43, 1),
      )),
    );
    return Portal(
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 520,
                height: 418,
                child: Material(
                  color: theme.popUp,
                  borderRadius: const BorderRadius.all(Radius.circular(13)),
                  elevation: 10,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(13)),
                    child: child,
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 16,
              right: 16,
              child: VersionInfoWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class VersionInfoWidget extends HookConsumerWidget {
  const VersionInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(brightnessThemeDataProvider);
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return NTapGestureDetector(
      n: 5,
      onTap: () => showLogPage(context),
      child: Text(
        info?.versionAndBuildNumber ?? '',
        style: TextStyle(
          fontSize: 14,
          color: theme.secondaryText,
        ),
      ),
    );
  }
}

class LandingModeSwitchButton extends HookConsumerWidget {
  const LandingModeSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = ref.watch(brightnessThemeDataProvider);
    final mode = ref.watch(landingModeControllerProvider);
    final String buttonText;
    switch (mode) {
      case LandingMode.qrcode:
        buttonText = l10n.signWithMobileNumber;
      case LandingMode.mobile:
        buttonText = l10n.signWithQrcode;
    }
    return TextButton(
      onPressed: () {
        switch (mode) {
          case LandingMode.qrcode:
            ref
                .read(landingModeControllerProvider.notifier)
                .changeMode(LandingMode.mobile);
          case LandingMode.mobile:
            ref
                .read(landingModeControllerProvider.notifier)
                .changeMode(LandingMode.qrcode);
        }
      },
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: theme.accent,
        ),
      ),
    );
  }
}
