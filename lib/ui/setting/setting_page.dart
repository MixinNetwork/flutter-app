import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/assets.dart';
import 'package:flutter_app/ui/setting/bloc/setting_selected_cubit.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 64),
            const _UserProfile(),
            const SizedBox(height: 24),
            Column(
              children: [
                const _ItemContainer(
                  child: _Item(
                    assetName: Assets.assetsImagesIcProfileSvg,
                    title: 'Edit Profile',
                  ),
                ),
                const SizedBox(height: 10),
                _ItemContainer(
                  child: Column(
                    children: const [
                      _Item(
                        assetName: Assets.assetsImagesIcNotificationSvg,
                        title: 'Notification',
                      ),
                      _Item(
                        assetName: Assets.assetsImagesIcBackupSvg,
                        title: 'Chat Backup',
                      ),
                      _Item(
                        assetName: Assets.assetsImagesIcStorageUsageSvg,
                        title: 'Data and Storage Usage',
                      ),
                      _Item(
                        assetName: Assets.assetsImagesIcAppearanceSvg,
                        title: 'Appearance',
                      ),
                      _Item(
                        assetName: Assets.assetsImagesIcAboutSvg,
                        title: 'About',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ItemContainer(
              child: _Item(
                assetName: Assets.assetsImagesIcSignOutSvg,
                title: 'Sign Out',
                onTap: () {},
                color: BrightnessData.dynamicColor(
                  context,
                  const Color.fromRGBO(246, 112, 112, 1),
                  darkColor: const Color.fromRGBO(246, 112, 112, 1),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({
    Key key,
    @required this.assetName,
    @required this.title,
    this.color,
    this.onTap,
  }) : super(key: key);

  final String assetName;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dynamicColor = color ??
        BrightnessData.dynamicColor(
          context,
          const Color.fromRGBO(51, 51, 51, 1),
          darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
        );
    final backgroundColor = BrightnessData.dynamicColor(
      context,
      const Color.fromRGBO(246, 247, 250, 1),
      darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
    );
    return BlocConverter<SettingSelectedCubit, String, bool>(
        converter: (state) => state == title,
        builder: (context, selected) {
          var selectedBackgroundColor = backgroundColor;
          if (selected) {
            selectedBackgroundColor = Color.alphaBlend(
              BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(0, 0, 0, 0.05),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.06),
              ),
              backgroundColor,
            );
          }
          return InteractableDecoratedBox(
            decoration: BoxDecoration(
              color: selectedBackgroundColor,
            ),
            onTap: () {
              if (onTap == null) {
                BlocProvider.of<SettingSelectedCubit>(context).emit(title);
                MixinRouter.instance.pushPage(SettingSelectedCubit.titlePageMap[
                    BlocProvider.of<SettingSelectedCubit>(context).state]);
                return;
              }

              onTap?.call();
            },
            child: Padding(
              padding: const EdgeInsets.only(
                top: 17,
                bottom: 17,
                left: 16,
                right: 10,
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    assetName,
                    width: 24,
                    height: 24,
                    color: dynamicColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: dynamicColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    Assets.assetsImagesIcArrowRightSvg,
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
            ),
          );
        });
  }
}

class _ItemContainer extends StatelessWidget {
  const _ItemContainer({
    Key key,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.child,
  }) : super(key: key);

  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: child,
        ),
      );
}

class _UserProfile extends StatelessWidget {
  const _UserProfile({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            Assets.assetsImagesAvatarPng,
            width: 90,
            height: 90,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Diego Morata',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(51, 51, 51, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.9),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mixin ID: 220021',
          style: TextStyle(
            fontSize: 14,
            color: BrightnessData.dynamicColor(
              context,
              const Color.fromRGBO(188, 190, 195, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
            ),
          ),
        ),
      ],
    );
  }
}
