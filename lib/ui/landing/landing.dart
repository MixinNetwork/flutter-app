import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/system/package_info.dart';
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

class LandingPage extends HookWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modeCubit = useBloc(() => LandingModeCubit());
    final mode = useBlocState<LandingModeCubit, LandingMode>(bloc: modeCubit);
    final Widget child;
    switch (mode) {
      case LandingMode.qrcode:
        child = const LandingQrCodeWidget();
        break;
      case LandingMode.mobile:
        child = const LoginWithMobileWidget();
        break;
    }
    return BlocProvider.value(
      value: modeCubit,
      child: _LandingScaffold(child: child),
    );
  }
}

class _LandingScaffold extends HookWidget {
  const _LandingScaffold({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(getPackageInfo, null).data;
    return Scaffold(
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
                borderRadius: BorderRadius.circular(13),
                elevation: 10,
                child: child,
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
    );
  }
}

class LandingModeSwitchButton extends HookWidget {
  const LandingModeSwitchButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mode = useBlocState<LandingModeCubit, LandingMode>();
    final String buttonText;
    switch (mode) {
      case LandingMode.qrcode:
        buttonText = context.l10n.loginWithMobile;
        break;
      case LandingMode.mobile:
        buttonText = context.l10n.loginWithQRCode;
        break;
    }
    return TextButton(
      onPressed: () {
        final modeCubit = context.read<LandingModeCubit>();
        switch (mode) {
          case LandingMode.qrcode:
            modeCubit.changeMode(LandingMode.mobile);
            break;
          case LandingMode.mobile:
            modeCubit.changeMode(LandingMode.qrcode);
            break;
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
