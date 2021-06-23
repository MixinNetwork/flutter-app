import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../account/account_server.dart';
import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../generated/l10n.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/brightness_observer.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../../widgets/window/move_window.dart';
import '../home/bloc/multi_auth_cubit.dart';
import '../home/route/responsive_navigator_cubit.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 64,
              child: MoveWindow(behavior: HitTestBehavior.opaque),
            ),
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
                      _Item(
                        assetName: Resources.assetsImagesIcAppearanceSvg,
                        pageName: ResponsiveNavigatorCubit.appearancePage,
                        title: Localization.of(context).appearance,
                      ),
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
                onTap: () async {
                  await runFutureWithToast(
                    context,
                    () async {
                      try {
                        final accountServer = context.read<AccountServer>();
                        await accountServer.signOutAndClear();
                      } catch (e) {
                        if (e is! MixinApiError) rethrow;
                      }
                    }(),
                  );
                  context.read<MultiAuthCubit>().signOut();
                },
                color: BrightnessData.themeOf(context).red,
                enableTrailingArrow: false,
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
    this.enableTrailingArrow = true,
  }) : super(key: key);

  final String assetName;
  final String title;
  final String? pageName;
  final Color? color;
  final VoidCallback? onTap;
  final bool enableTrailingArrow;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ResponsiveNavigatorCubit, ResponsiveNavigatorState, bool>(
        converter: (state) =>
            !state.navigationMode &&
            state.pages.any((element) => pageName == element.name),
        builder: (context, selected) => CellItem(
          leading: SvgPicture.asset(
            assetName,
            width: 24,
            height: 24,
            color: color ?? BrightnessData.themeOf(context).text,
          ),
          title: Text(title),
          color: color,
          selected: selected,
          onTap: () {
            if (onTap == null && pageName != null) {
              context.read<ResponsiveNavigatorCubit>()
                ..popWhere((page) => ResponsiveNavigatorCubit.settingPageNameSet
                    .contains(page.name))
                ..pushPage(pageName!);
              return;
            }

            onTap?.call();
          },
          trailing: enableTrailingArrow ? const Arrow() : null,
        ),
      );
}

class _UserProfile extends StatelessWidget {
  const _UserProfile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            final account =
                context.read<MultiAuthCubit>().state.current!.account;
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
