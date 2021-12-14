import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/resources.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import 'bloc/landing_cubit.dart';

class LandingPage extends HookWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = useMemoizedFuture(() => packageInfoFuture, null).data;
    final locale = useMemoized(() => Localizations.localeOf(context));

    final landingCubit = useBloc(() => LandingCubit(
          context.multiAuthCubit,
          locale,
        ));

    final status =
        useBlocStateConverter<LandingCubit, LandingState, LandingStatus>(
      bloc: landingCubit,
      converter: (state) => state.status,
    );

    final Widget child;
    if (status == LandingStatus.init) {
      child = _Loading(
        title: context.l10n.initializing,
        message: context.l10n.chatInputHint,
      );
    } else if (status == LandingStatus.provisioning) {
      child = _Loading(
        title: context.l10n.provisioning,
        message: Localization.current.chatInputHint,
      );
    } else {
      child = const _QrCode();
    }

    return BlocProvider.value(
      value: landingCubit,
      child: Scaffold(
        backgroundColor: context.dynamicColor(
          const Color.fromRGBO(255, 255, 255, 1),
          darkColor: const Color.fromRGBO(35, 39, 43, 1),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: child,
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

class _QrCode extends HookWidget {
  const _QrCode({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final url = useBlocStateConverter<LandingCubit, LandingState, String?>(
        converter: (state) => state.authUrl);

    final visible = useBlocStateConverter<LandingCubit, LandingState, bool>(
        converter: (state) => state.status == LandingStatus.needReload);

    final errorMessage =
        useBlocStateConverter<LandingCubit, LandingState, String?>(
      converter: (state) => state.errorMessage,
    );

    Widget? qrCode;
    if (url != null) {
      qrCode = QrImage(
        data: url,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
      );
    }

    return SizedBox(
      width: 423,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: SizedBox.fromSize(
              size: const Size.square(200),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  qrCode ?? const SizedBox(),
                  if (qrCode != null)
                    Center(
                      child: Image.asset(
                        Resources.assetsImagesLogoPng,
                        width: 44,
                        height: 44,
                      ),
                    ),
                  Visibility(
                    visible: visible,
                    child: _Retry(
                      errorMessage: errorMessage,
                      onTap: () =>
                          context.read<LandingCubit>().requestAuthUrl(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.pageLandingLoginTitle,
            style: TextStyle(
              fontSize: 22,
              color: context.theme.text,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.pageLandingLoginMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.dynamicColor(
                const Color.fromRGBO(187, 190, 195, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({
    Key? key,
    required this.title,
    required this.message,
  }) : super(key: key);

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.theme.text;
    return SizedBox(
      width: 375,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.dynamicColor(
                const Color.fromRGBO(188, 190, 195, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
              ),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({
    Key? key,
    required this.onTap,
    this.errorMessage,
  }) : super(key: key);

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
                    width: 50,
                    height: 50,
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      context.l10n.pageLandingClickToReload,
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
