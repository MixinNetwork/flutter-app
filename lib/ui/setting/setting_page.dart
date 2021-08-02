import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:provider/provider.dart';

import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/action_button.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../home/bloc/multi_auth_cubit.dart';
import '../home/home.dart';
import '../home/route/responsive_navigator_cubit.dart';

class SettingPage extends HookWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasDrawer = context.watch<HasDrawerValueNotifier>();

    Widget? leading;
    if (hasDrawer.value) {
      leading = ActionButton(
        onTapUp: (event) => Scaffold.of(context).openDrawer(),
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.menu,
          size: 20,
          color: context.theme.icon,
        ),
      );
    }

    return Column(
      children: [
        MixinAppBar(
          backgroundColor: Colors.transparent,
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: leading ?? const SizedBox(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const _UserProfile(),
                const SizedBox(height: 24),
                Column(
                  children: [
                    CellGroup(
                      child: _Item(
                        assetName: Resources.assetsImagesIcProfileSvg,
                        pageName: ResponsiveNavigatorCubit.editProfilePage,
                        title: context.l10n.editProfile,
                      ),
                    ),
                    CellGroup(
                      child: Column(
                        children: [
                          _Item(
                            assetName: Resources.assetsImagesIcNotificationSvg,
                            pageName: ResponsiveNavigatorCubit.notificationPage,
                            title: context.l10n.notification,
                          ),
                          _Item(
                            assetName: Resources.assetsImagesIcBackupSvg,
                            pageName: ResponsiveNavigatorCubit.chatBackupPage,
                            title: context.l10n.chatBackup,
                          ),
                          _Item(
                            assetName: Resources.assetsImagesIcStorageUsageSvg,
                            pageName: ResponsiveNavigatorCubit
                                .dataAndStorageUsagePage,
                            title: context.l10n.dataAndStorageUsage,
                          ),
                          _Item(
                            assetName: Resources.assetsImagesIcAppearanceSvg,
                            pageName: ResponsiveNavigatorCubit.appearancePage,
                            title: context.l10n.appearance,
                          ),
                          _Item(
                            assetName: Resources.assetsImagesIcAboutSvg,
                            pageName: ResponsiveNavigatorCubit.aboutPage,
                            title: context.l10n.about,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                CellGroup(
                  child: _Item(
                    assetName: Resources.assetsImagesIcSignOutSvg,
                    title: context.l10n.signOut,
                    onTap: () async {
                      await runFutureWithToast(
                        context,
                        () async {
                          try {
                            final accountServer = context.accountServer;
                            await accountServer.signOutAndClear();
                          } catch (e) {
                            if (e is! MixinApiError) rethrow;
                          }
                        }(),
                      );
                      context.multiAuthCubit.signOut();
                    },
                    color: context.theme.red,
                    enableTrailingArrow: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
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
            color: color ?? context.theme.text,
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
            final account = context.multiAuthState.current!.account;
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
                color: context.theme.text,
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
                color: context.dynamicColor(
                  const Color.fromRGBO(188, 190, 195, 1),
                  darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
                ),
              ),
            ),
          ),
        ],
      );
}
