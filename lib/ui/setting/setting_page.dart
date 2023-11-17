import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/resources.dart';
import '../../utils/app_lifecycle.dart';
import '../../utils/extension/extension.dart';
import '../../utils/hook.dart';
import '../../utils/local_notification_center.dart';
import '../../widgets/action_button.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/avatar_view/avatar_view.dart';
import '../../widgets/cell.dart';
import '../../widgets/high_light_text.dart';
import '../../widgets/toast.dart';
import '../home/home.dart';
import '../provider/account/multi_auth_provider.dart';
import '../provider/navigation/responsive_navigator_provider.dart';

class SettingPage extends HookConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final userHasPin = ref
        .watch(authProvider.select((value) => value?.account.hasPin == true));

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
                        leadingAssetName: Resources.assetsImagesIcProfileSvg,
                        pageName:
                            ResponsiveNavigatorStateNotifier.editProfilePage,
                        title: context.l10n.editProfile,
                      ),
                    ),
                    CellGroup(
                      child: Column(
                        children: [
                          if (Platform.isIOS &&
                              userHasPin &&
                              context.accountServer.loginByPhoneNumber)
                            _Item(
                              leadingAssetName:
                                  Resources.assetsImagesAccountSvg,
                              pageName:
                                  ResponsiveNavigatorStateNotifier.accountPage,
                              title: context.l10n.account,
                            ),
                          _Item(
                            leadingAssetName:
                                Resources.assetsImagesIcNotificationSvg,
                            pageName: ResponsiveNavigatorStateNotifier
                                .notificationPage,
                            title: context.l10n.notifications,
                            trailing: hasNotificationPermission == false
                                ? Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: SvgPicture.asset(
                                      Resources.assetsImagesTriangleWarningSvg,
                                      colorFilter: ColorFilter.mode(
                                          context.theme.red, BlendMode.srcIn),
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
                            leadingAssetName:
                                Resources.assetsImagesIcStorageUsageSvg,
                            pageName: ResponsiveNavigatorStateNotifier
                                .dataAndStorageUsagePage,
                            title: context.l10n.dataAndStorageUsage,
                          ),
                          _Item(
                            leadingAssetName: Resources.assetsImagesShieldSvg,
                            pageName:
                                ResponsiveNavigatorStateNotifier.securityPage,
                            title: context.l10n.security,
                          ),
                          _Item(
                            leadingAssetName: Resources.assetsImagesProxySvg,
                            pageName:
                                ResponsiveNavigatorStateNotifier.proxyPage,
                            title: context.l10n.proxy,
                          ),
                          _Item(
                            leadingAssetName:
                                Resources.assetsImagesIcAppearanceSvg,
                            pageName:
                                ResponsiveNavigatorStateNotifier.appearancePage,
                            title: context.l10n.appearance,
                          ),
                          _Item(
                            leadingAssetName: Resources.assetsImagesIcAboutSvg,
                            pageName:
                                ResponsiveNavigatorStateNotifier.aboutPage,
                            title: context.l10n.about,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                CellGroup(
                  child: _Item(
                    leadingAssetName: Resources.assetsImagesIcSignOutSvg,
                    title: context.l10n.signOut,
                    onTap: () async {
                      final succeed = await runFutureWithToast(
                        context.accountServer.signOutAndClear(),
                      );
                      if (!succeed) return;
                      context.multiAuthChangeNotifier
                          .signOut(context.accountServer.userId);
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

class _Item extends HookConsumerWidget {
  const _Item({
    required this.title,
    this.leadingAssetName,
    this.pageName,
    this.color,
    this.onTap,
    this.trailing = const Arrow(),
    // ignore: unused_element
    this.leading,
  });

  final String? leadingAssetName;
  final Widget? leading;
  final String title;
  final String? pageName;
  final Color? color;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(responsiveNavigatorProvider.select((value) =>
        !value.routeMode &&
        value.pages.any((element) => pageName == element.name)));

    return CellItem(
      leading: leading ??
          (leadingAssetName != null
              ? SvgPicture.asset(
                  leadingAssetName!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      color ?? context.theme.text, BlendMode.srcIn),
                )
              : null),
      title: AutoSizeText(title, maxLines: 1),
      color: color ?? context.theme.text,
      selected: selected,
      onTap: () {
        if (onTap == null && pageName != null) {
          context.providerContainer.read(responsiveNavigatorProvider.notifier)
            ..popWhere((page) => ResponsiveNavigatorStateNotifier
                .settingPageNameSet
                .contains(page.name))
            ..pushPage(pageName!);
          return;
        }

        onTap?.call();
      },
      trailing: trailing,
    );
  }
}

class _UserProfile extends HookConsumerWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (fullName, identityNumber) = ref.watch(authAccountProvider
        .select((value) => (value?.fullName, value?.identityNumber)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Builder(builder: (context) {
          final account = context.account!;
          return AvatarWidget(
            userId: account.userId,
            name: account.fullName,
            avatarUrl: account.avatarUrl,
            size: 90,
          );
        }),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomText(
            fullName ?? '',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: context.theme.text,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mixin ID: $identityNumber',
          style: TextStyle(
            fontSize: 14,
            color: context.dynamicColor(
              const Color.fromRGBO(188, 190, 195, 1),
              darkColor: const Color.fromRGBO(255, 255, 255, 0.4),
            ),
          ),
        ),
      ],
    );
  }
}
