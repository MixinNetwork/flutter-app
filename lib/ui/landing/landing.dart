import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../account/account_key_value.dart';
import '../../crypto/signal/signal_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hive_key_values.dart';
import '../../utils/hook.dart';
import '../../utils/mixin_api_client.dart';
import '../../utils/system/package_info.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialog.dart';
import '../../widgets/toast.dart';
import '../provider/account_server_provider.dart';
import '../setting/log_page.dart';
import 'landing_mobile.dart';
import 'landing_qrcode.dart';

enum LandingMode {
  qrcode,
  mobile,
}

class LandingModeCubit extends Cubit<LandingMode> {
  LandingModeCubit() : super(LandingMode.qrcode);

  void changeMode(LandingMode mode) => emit(mode);
}

class LandingPage extends HookConsumerWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountServerHasError =
        ref.watch(accountServerProvider.select((value) => value.hasError));

    final modeCubit = useBloc(LandingModeCubit.new);
    final mode = useBlocState<LandingModeCubit, LandingMode>(bloc: modeCubit);

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
    return BlocProvider.value(
      value: modeCubit,
      child: LandingScaffold(child: child),
    );
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

                  try {
                    await createClient(
                      userId: authState.account.userId,
                      sessionId: authState.account.sessionId,
                      privateKey: authState.privateKey,
                      loginByPhoneNumber:
                          AccountKeyValue.instance.primarySessionId == null,
                    )
                        .accountApi
                        .logout(LogoutRequest(authState.account.sessionId));
                  } catch (err, stacktrace) {
                    e('logout error: $err $stacktrace');
                  }
                  await clearKeyValues();
                  await SignalDatabase.get.clear();
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
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Portal(
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

class VersionInfoWidget extends HookWidget {
  const VersionInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return NTapGestureDetector(
      n: 5,
      onTap: () => showLogPage(context),
      child: Text(
        info?.versionAndBuildNumber ?? '',
        style: TextStyle(
          fontSize: 14,
          color: context.theme.secondaryText,
        ),
      ),
    );
  }
}

class LandingModeSwitchButton extends HookConsumerWidget {
  const LandingModeSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = useBlocState<LandingModeCubit, LandingMode>();
    final String buttonText;
    switch (mode) {
      case LandingMode.qrcode:
        buttonText = context.l10n.signWithPhoneNumber;
      case LandingMode.mobile:
        buttonText = context.l10n.signWithQrcode;
    }
    return TextButton(
      onPressed: () {
        final modeCubit = context.read<LandingModeCubit>();
        switch (mode) {
          case LandingMode.qrcode:
            modeCubit.changeMode(LandingMode.mobile);
          case LandingMode.mobile:
            modeCubit.changeMode(LandingMode.qrcode);
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
