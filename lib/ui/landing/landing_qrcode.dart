import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/platform.dart';
import 'bloc/landing_cubit.dart';
import 'bloc/landing_state.dart';
import 'landing.dart';

class LandingQrCodeWidget extends HookConsumerWidget {
  const LandingQrCodeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = useMemoized(() => Localizations.localeOf(context));

    final landingCubit = useBloc(() => LandingQrCodeCubit(
          context.multiAuthChangeNotifier,
          locale,
        ));

    final status =
        useBlocStateConverter<LandingQrCodeCubit, LandingState, LandingStatus>(
      bloc: landingCubit,
      converter: (state) => state.status,
    );

    final Widget child;
    if (status == LandingStatus.init) {
      child = Center(
        child: _Loading(
          title: context.l10n.initializing,
          message: context.l10n.chatHintE2e,
        ),
      );
    } else if (status == LandingStatus.provisioning) {
      child = Center(
        child: _Loading(
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
    return BlocProvider.value(
      value: landingCubit,
      child: child,
    );
  }
}

class _QrCode extends HookConsumerWidget {
  const _QrCode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url =
        useBlocStateConverter<LandingQrCodeCubit, LandingState, String?>(
            converter: (state) => state.authUrl);

    final visible =
        useBlocStateConverter<LandingQrCodeCubit, LandingState, bool>(
            converter: (state) => state.status == LandingStatus.needReload);

    final errorMessage =
        useBlocStateConverter<LandingQrCodeCubit, LandingState, String?>(
      converter: (state) => state.errorMessage,
    );

    Widget? qrCode;

    if (url != null) {
      qrCode = QrImageView(data: url, backgroundColor: Colors.white);
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
                if (qrCode != null)
                  Center(
                    child: Image.asset(
                      Resources.assetsImagesLogoPng,
                      width: 36,
                      height: 36,
                    ),
                  ),
                Visibility(
                  visible: visible,
                  child: _Retry(
                    errorMessage: errorMessage,
                    onTap: () =>
                        context.read<LandingQrCodeCubit>().requestAuthUrl(),
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

class _Loading extends StatelessWidget {
  const _Loading({
    required this.title,
    required this.message,
  });

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
