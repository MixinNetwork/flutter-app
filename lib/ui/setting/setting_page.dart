import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/interacter_decorated_box.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/generated/l10n.dart';

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
                _ItemContainer(
                  child: _Item(
                    assetName: Resources.assetsImagesIcProfileSvg,
                    name: 'Edit Profile',
                    title: Localization.of(context).editProfile,
                  ),
                ),
                const SizedBox(height: 10),
                _ItemContainer(
                  child: Column(
                    children: [
                      _Item(
                        assetName: Resources.assetsImagesIcNotificationSvg,
                        name: 'Notification',
                        title: Localization.of(context).notification,
                      ),
                      _Item(
                        assetName: Resources.assetsImagesIcBackupSvg,
                        name: 'Chat Backup',
                        title: Localization.of(context).chatBackup,
                      ),
                      _Item(
                        assetName: Resources.assetsImagesIcStorageUsageSvg,
                        name: 'Data and Storage Usage',
                        title: Localization.of(context).dataAndStorageUsage,
                      ),
                      _Item(
                        assetName: Resources.assetsImagesIcAppearanceSvg,
                        name: 'Appearance',
                        title: Localization.of(context).appearance,
                      ),
                      _Item(
                        assetName: Resources.assetsImagesIcAboutSvg,
                        name: 'About',
                        title: Localization.of(context).about,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ItemContainer(
              child: _Item(
                assetName: Resources.assetsImagesIcSignOutSvg,
                title: Localization.of(context).signOut,
                name: 'Sign Out',
                onTap: () => MultiAuthCubit.of(context).signOut(),
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
    @required this.name,
    this.color,
    this.onTap,
  }) : super(key: key);

  final String assetName;
  final String title;
  final String name;
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
    return BlocConverter<ResponsiveNavigatorCubit, ResponsiveNavigatorState,
            bool>(
        converter: (state) =>
            !state.navigationMode &&
            state.pages.any((element) =>
                ResponsiveNavigatorCubit.settingTitlePageMap[name] ==
                element.name),
        builder: (context, selected) {
          var selectedBackgroundColor = backgroundColor;
          if (selected &&
              !ResponsiveNavigatorCubit.of(context).state.navigationMode) {
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
                ResponsiveNavigatorCubit.of(context).pushPage(
                    ResponsiveNavigatorCubit.settingTitlePageMap[name]);
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
                    Resources.assetsImagesIcArrowRightSvg,
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
          child: BlocConverter<MultiAuthCubit, MultiAuthState, String>(
            converter: (state) => state.current?.account?.avatarUrl,
            when: (a, b) => b != null,
            builder: (context, avatarUrl) => CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 90,
              height: 90,
            ),
          ),
        ),
        const SizedBox(height: 10),
        BlocConverter<MultiAuthCubit, MultiAuthState, String>(
          converter: (state) => state.current?.account?.fullName,
          when: (a, b) => b != null,
          builder: (context, fullName) => Text(
            fullName,
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
        ),
        const SizedBox(height: 4),
        BlocConverter<MultiAuthCubit, MultiAuthState, String>(
          converter: (state) => state.current?.account?.identityNumber,
          when: (a, b) => b != null,
          builder: (context, identityNumber) => Text(
            'Mixin ID: $identityNumber',
            style: TextStyle(
              fontSize: 14,
              color: BrightnessData.dynamicColor(
                context,
                const Color.fromRGBO(188, 190, 195, 1),
                darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
