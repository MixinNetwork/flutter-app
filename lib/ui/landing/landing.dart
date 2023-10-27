import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../crypto/signal/signal_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hive_key_values.dart';
import '../../utils/hook.dart';
import '../../utils/mixin_api_client.dart';
import '../../utils/system/package_info.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../provider/account_server_provider.dart';
import '../provider/hive_key_value_provider.dart';
import 'landing_mobile.dart';
import 'landing_qrcode.dart';

enum _LandingMode {
  qrcode,
  mobile,
}

final _landingModeProvider =
    StateProvider.autoDispose<_LandingMode>((ref) => _LandingMode.qrcode);

class LandingPage extends HookConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServerHasError =
        ref.watch(accountServerProvider.select((value) => value.hasError));
    final mode = ref.watch(_landingModeProvider);
    Widget child;
    switch (mode) {
      case _LandingMode.qrcode:
        child = const LandingQrCodeWidget();
        break;
      case _LandingMode.mobile:
        child = const LoginWithMobileWidget();
        break;
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
    final accountServerError = ref.watch(accountServerProvider);

    final errorText = 'Error: ${accountServerError.error}';
    final stackTraceText = 'StackTrace: ${accountServerError.stackTrace}';

    return Padding(
      padding: const EdgeInsets.only(top: 56, bottom: 30, right: 48, left: 48),
      child: Column(
        children: [
          Text(
            context.l10n.unknowError,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.red,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DefaultTextStyle(
              style: TextStyle(
                color: context.theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              child: SelectionArea(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.sidebarSelected,
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
                      ClipboardData(text: '$errorText\n$stackTraceText'));
                  showToastSuccessful();
                },
                child: Text(context.l10n.copy),
              ),
              MixinButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 14,
                ),
                onTap: () async {
                  final authState = context.auth;
                  if (authState == null) return;

                  final accountKeyValue =
                      await ref.read(currentAccountKeyValueProvider.future);

                  await createClient(
                    userId: authState.account.userId,
                    sessionId: authState.account.sessionId,
                    privateKey: authState.privateKey,
                    loginByPhoneNumber:
                        accountKeyValue?.primarySessionId == null,
                  )
                      .accountApi
                      .logout(LogoutRequest(authState.account.sessionId));
                  await clearKeyValues();
                  final signalDb = await SignalDatabase.connect(
                    identityNumber: authState.account.identityNumber,
                    openForLogin: true,
                    fromMainIsolate: true,
                  );
                  await signalDb.clear();
                  await signalDb.close();
                  context.multiAuthChangeNotifier.signOut();
                },
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LandingScaffold extends HookConsumerWidget {
  const LandingScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return Portal(
      child: Scaffold(
        backgroundColor: context.dynamicColor(
          const Color(0xFFE5E5E5),
          darkColor: const Color.fromRGBO(35, 39, 43, 1),
        ),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 520,
                height: 418,
                child: Material(
                  color: context.theme.popUp,
                  borderRadius: const BorderRadius.all(Radius.circular(13)),
                  elevation: 10,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(13)),
                    child: child,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                info?.versionAndBuildNumber ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: context.theme.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingModeSwitchButton extends HookConsumerWidget {
  const LandingModeSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_landingModeProvider);
    final String buttonText;
    switch (mode) {
      case _LandingMode.qrcode:
        buttonText = context.l10n.signWithPhoneNumber;
        break;
      case _LandingMode.mobile:
        buttonText = context.l10n.signWithQrcode;
        break;
    }
    return TextButton(
      onPressed: () {
        final notifier = ref.read(_landingModeProvider.notifier);
        switch (mode) {
          case _LandingMode.qrcode:
            notifier.state = _LandingMode.mobile;
          case _LandingMode.mobile:
            notifier.state = _LandingMode.qrcode;
        }
      },
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: context.theme.accent,
        ),
      ),
    );
  }
}
