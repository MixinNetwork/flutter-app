import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator_cubit.dart';
import 'package:flutter_app/bloc/bloc_converter.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/widgets/avatar_view/avatar_view.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/cell.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 64),
            const _UserProfile(),
            const SizedBox(height: 24),
            Column(
              children: [
                CellGroup(
                  child: _Item(
                    assetName: Resources.assetsImagesIcProfileSvg,
                    pageName: ResponsiveNavigatorCubit.editProfilePage,
                    title: Localization.of(context).editProfile,
                  ),
                ),
                CellGroup(
                  child: Column(
                    children: [
                      _Item(
                        assetName: Resources.assetsImagesIcNotificationSvg,
                        pageName: ResponsiveNavigatorCubit.notificationPage,
                        title: Localization.of(context).notification,
                      ),
                      _Item(
                        assetName: Resources.assetsImagesIcBackupSvg,
                        pageName: ResponsiveNavigatorCubit.chatBackupPage,
                        title: Localization.of(context).chatBackup,
                      ),
                      _Item(
                        assetName: Resources.assetsImagesIcStorageUsageSvg,
                        pageName:
                            ResponsiveNavigatorCubit.dataAndStorageUsagePage,
                        title: Localization.of(context).dataAndStorageUsage,
                      ),
                      // _Item(
                      //   assetName: Resources.assetsImagesIcAppearanceSvg,
                      //   pageName: ResponsiveNavigatorCubit.appearancePage,
                      //   title: Localization.of(context).appearance,
                      // ),
                      _Item(
                        assetName: Resources.assetsImagesIcAboutSvg,
                        pageName: ResponsiveNavigatorCubit.aboutPage,
                        title: Localization.of(context).about,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            CellGroup(
              child: _Item(
                assetName: Resources.assetsImagesIcSignOutSvg,
                title: Localization.of(context).signOut,
                onTap: () => MultiAuthCubit.of(context).signOut(),
                color: BrightnessData.themeOf(context).red,
              ),
            ),
          ],
        ),
      );
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.assetName,
    required this.title,
    this.pageName,
    this.color,
    this.onTap,
  }) : super(key: key);

  final String assetName;
  final String title;
  final String? pageName;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ResponsiveNavigatorCubit, ResponsiveNavigatorState, bool>(
        converter: (state) =>
            !state.navigationMode &&
            state.pages.any((element) => pageName == element.name),
        builder: (context, selected) => CellItem(
          assetName: assetName,
          title: title,
          color: color,
          selected: selected,
          onTap: () {
            if (onTap == null && pageName != null) {
              context.read<ResponsiveNavigatorCubit>()
                ..popWhere((page) => ResponsiveNavigatorCubit
                    .settingTitlePageSet
                    .contains(page.name))
                ..pushPage(pageName!);
              return;
            }

            onTap?.call();
          },
        ),
      );
}

class _UserProfile extends StatelessWidget {
  const _UserProfile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(builder: (context) {
          final account = context.read<MultiAuthCubit>().state.current!.account;
          return AvatarWidget(
            userId: account.userId,
            name: account.fullName!,
            avatarUrl: account.avatarUrl,
            size: 90,
          );
        }),
        const SizedBox(height: 10),
        BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
          converter: (state) => state.current?.account.fullName,
          when: (a, b) => b != null,
          builder: (context, fullName) => Text(
            fullName ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: BrightnessData.themeOf(context).text,
            ),
          ),
        ),
        const SizedBox(height: 4),
        BlocConverter<MultiAuthCubit, MultiAuthState, String?>(
          converter: (state) => state.current?.account.identityNumber,
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
