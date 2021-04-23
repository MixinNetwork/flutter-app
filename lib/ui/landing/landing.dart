import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/landing/bloc/landing_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_app/generated/l10n.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return BlocProvider(
      create: (context) => LandingCubit(
        context.read<MultiAuthCubit>(),
        locale,
      ),
      child: Builder(
        builder: (BuildContext context) => Scaffold(
          backgroundColor: BrightnessData.dynamicColor(
            context,
            const Color.fromRGBO(255, 255, 255, 1),
            darkColor: const Color.fromRGBO(35, 39, 43, 1),
          ),
          body: Center(
            child: BlocConverter<LandingCubit, LandingState, LandingStatus>(
              converter: (state) => state.status,
              builder: (context, status) {
                if (status == LandingStatus.init)
                  return _Loading(
                    title: Localization.of(context).initializing,
                    message: Localization.of(context).pleaseWait,
                  );

                if (status == LandingStatus.provisioning)
                  return _Loading(
                    title: Localization.of(context).provisioning,
                    message: Localization.current.pleaseWait,
                  );

                return const _QrCode();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCode extends StatelessWidget {
  const _QrCode({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 423,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox.fromSize(
                size: const Size.square(200),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BlocConverter<LandingCubit, LandingState, String>(
                      converter: (state) => state.authUrl!,
                      builder: (context, url) => QrImage(
                        data: url,
                        version: QrVersions.auto,
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        embeddedImage:
                            const AssetImage(Resources.assetsImagesLogoPng),
                        embeddedImageStyle: QrEmbeddedImageStyle(
                          size: const Size(44, 44),
                        ),
                      ),
                    ),
                    BlocConverter<LandingCubit, LandingState, bool>(
                      converter: (state) =>
                          state.status == LandingStatus.needReload,
                      builder: (context, visible) => Visibility(
                        visible: visible,
                        child: _Retry(
                          onTap: () => BlocProvider.of<LandingCubit>(context)
                              .requestAuthUrl(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              Localization.of(context).pageLandingLoginTitle,
              style: TextStyle(
                fontSize: 22,
                color: BrightnessData.themeOf(context).text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              Localization.of(context).pageLandingLoginMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(187, 190, 195, 1),
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                ),
              ),
            ),
          ],
        ),
      );
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
    final primaryColor = BrightnessData.themeOf(context).text;
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
              color: BrightnessData.dynamicColor(
                context,
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
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.86),
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
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
                    Localization.of(context).pageLandingClickToReload,
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
      );
}
