import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

import '../../bloc/bloc_converter.dart';
import '../../constants/resources.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/local_notification_center.dart';
import '../../widgets/action_button.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/cell.dart';
import '../../widgets/toast.dart';
import '../home/bloc/multi_auth_cubit.dart';
import '../home/home.dart';
import '../home/route/responsive_navigator_cubit.dart';

class SettingPage extends HookWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final hasDrawer = context.watch<HasDrawerValueNotifier>();

    Widget? leading;
    if (hasDrawer.value) {
      leading = ActionButton(
        onTapUp: (event) => Scaffold.of(context).openDrawer(),
        child: Icon(
          Icons.menu,
          size: 20,
          color: context.theme.icon,
        ),
      );
    }

    final appActive = useValueListenable(appActiveListener);
    final hasNotificationPermission = useMemoizedFuture(
        requestNotificationPermission, null,
        keys: [appActive]).data;
    final controller = useScrollController();
    return Column(
      children: [
        MixinAppBar(
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: leading ?? const SizedBox(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
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
                            trailing: hasNotificationPermission == false
                                ? Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: SvgPicture.asset(
                                      Resources.assetsImagesTriangleWarningSvg,
                                      color: context.theme.red,
                                      width: 22,
                                      height: 22,
                                    ),
                                  )
                                : const Arrow(),
                            color: hasNotificationPermission == false
                                ? context.theme.red
                                : context.theme.text,
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
                      final succeed = await runFutureWithToast(
                        context,
                        context.accountServer.signOutAndClear(),
                      );
                      if (!succeed) return;
                      context.multiAuthCubit.signOut();
                    },
                    color: context.theme.red,
                    trailing: const SizedBox(),
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
    required this.assetName,
    required this.title,
    this.pageName,
    this.color,
    this.onTap,
    this.trailing = const Arrow(),
  });

  final String assetName;
  final String title;
  final String? pageName;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) =>
      BlocConverter<ResponsiveNavigatorCubit, ResponsiveNavigatorState, bool>(
        converter: (state) =>
            !state.routeMode &&
            state.pages.any((element) => pageName == element.name),
        builder: (context, selected) => CellItem(
          leading: SvgPicture.asset(
            assetName,
            width: 24,
            height: 24,
            color: color ?? context.theme.text,
          ),
          title: Text(title),
          color: color ?? context.theme.text,
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
          trailing: trailing,
        ),
      );
}

class _UserProfile extends StatelessWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(builder: (context) {
            final account = context.multiAuthState.currentUser!;
            return AvatarWidget(
              userId: account.userId,
              name: account.fullName,
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
