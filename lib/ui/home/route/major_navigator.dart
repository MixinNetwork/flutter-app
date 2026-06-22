import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../provider/major_navigation_provider.dart';
import '../../setting/about_page.dart';
import '../../setting/account_delete_page.dart';
import '../../setting/account_page.dart';
import '../../setting/appearance_page.dart';
import '../../setting/backup_page.dart';
import '../../setting/edit_profile_page.dart';
import '../../setting/notification_page.dart';
import '../../setting/proxy_page.dart';
import '../../setting/security_page.dart';
import '../../setting/storage_page.dart';
import '../../setting/storage_usage_detail_page.dart';
import '../../setting/storage_usage_list_page.dart';
import '../chat/chat_page.dart';

class MajorNavigator extends HookConsumerWidget {
  const MajorNavigator({
    required this.leftPage,
    required this.rightEmptyPage,
    required this.switchWidth,
    super.key,
  });

  final MaterialPage leftPage;
  final MaterialPage rightEmptyPage;
  final double switchWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(majorNavigationProvider.notifier);
    final state = ref.watch(majorNavigationProvider);

    return LayoutBuilder(
      builder: (context, boxConstraints) {
        final routeMode = boxConstraints.maxWidth < switchWidth;
        notifier.updateRouteMode(routeMode);
        return Row(
          children: [
            if (!routeMode) leftPage.child,
            Expanded(
              child: ClipRect(
                child: Navigator(
                  transitionDelegate: WithoutAnimationDelegate(
                    routeWithoutAnimation: {leftPage.name, rightEmptyPage.name},
                  ),
                  onDidRemovePage: (page) {},
                  pages: [
                    if (routeMode) leftPage,
                    if (!routeMode && state.entries.isEmpty) rightEmptyPage,
                    ...state.entries.map(_pageFor),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

MaterialPage _pageFor(MajorNavigationEntry entry) {
  switch (entry.destination) {
    case MajorNavigationDestination.chatPage:
      return MaterialPage(
        key: const ValueKey(MajorNavigationDestination.chatPage),
        name: MajorNavigationDestination.chatPage.name,
        child: const ChatPage(),
      );
    case MajorNavigationDestination.editProfilePage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.editProfilePage),
        name: 'editProfilePage',
        child: EditProfilePage(key: ValueKey('editProfilePage')),
      );
    case MajorNavigationDestination.notificationPage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.notificationPage),
        name: 'notificationPage',
        child: NotificationPage(key: ValueKey('notificationPage')),
      );
    case MajorNavigationDestination.chatBackupPage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.chatBackupPage),
        name: 'chatBackupPage',
        child: BackupPage(key: ValueKey('chatBackupPage')),
      );
    case MajorNavigationDestination.dataAndStorageUsagePage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.dataAndStorageUsagePage),
        name: 'dataAndStorageUsagePage',
        child: StoragePage(key: ValueKey('dataAndStorageUsagePage')),
      );
    case MajorNavigationDestination.aboutPage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.aboutPage),
        name: 'aboutPage',
        child: AboutPage(key: ValueKey('aboutPage')),
      );
    case MajorNavigationDestination.storageUsage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.storageUsage),
        name: 'storageUsage',
        child: StorageUsageListPage(key: ValueKey('storageUsage')),
      );
    case MajorNavigationDestination.storageUsageDetail:
      final arguments = entry.arguments;
      if (arguments == null || arguments is! (String, String)) {
        throw ArgumentError('Invalid route');
      }
      return MaterialPage(
        key: const ValueKey(MajorNavigationDestination.storageUsageDetail),
        name: 'storageUsageDetail',
        child: StorageUsageDetailPage(
          key: const ValueKey('storageUsageDetail'),
          name: arguments.$1,
          conversationId: arguments.$2,
        ),
      );
    case MajorNavigationDestination.appearancePage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.appearancePage),
        name: 'appearancePage',
        child: AppearancePage(key: ValueKey('appearancePage')),
      );
    case MajorNavigationDestination.accountPage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.accountPage),
        name: 'accountPage',
        child: AccountPage(key: ValueKey('accountPage')),
      );
    case MajorNavigationDestination.accountDeletePage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.accountDeletePage),
        name: 'accountDeletePage',
        child: AccountDeletePage(key: ValueKey('accountDeletePage')),
      );
    case MajorNavigationDestination.proxyPage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.proxyPage),
        name: 'proxyPage',
        child: ProxyPage(key: ValueKey('proxyPage')),
      );
    case MajorNavigationDestination.securityPage:
      return const MaterialPage(
        key: ValueKey(MajorNavigationDestination.securityPage),
        name: 'securityPage',
        child: SecurityPage(key: ValueKey('securityPage')),
      );
  }
}

class WithoutAnimationDelegate<T> extends TransitionDelegate<T> {
  const WithoutAnimationDelegate({required this.routeWithoutAnimation})
    : super();

  final Set<String?> routeWithoutAnimation;

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
    pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];

    void handleExitingRoute(RouteTransitionRecord? location, bool isLast) {
      final exitingPageRoute = locationToExitingPageRoute[location];
      if (exitingPageRoute == null) return;
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final hasPagelessRoute = pageRouteToPagelessRoutes.containsKey(
          exitingPageRoute,
        );
        final isLastExitingPageRoute =
            isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute.markForComplete(
            exitingPageRoute.route.currentResult,
          );
        }
        if (hasPagelessRoute) {
          final pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute];
          for (final pagelessRoute in pagelessRoutes!) {
            if (pagelessRoute.isWaitingForExitingDecision) {
              if (isLastExitingPageRoute &&
                  pagelessRoute == pagelessRoutes.last) {
                pagelessRoute.markForPop(pagelessRoute.route.currentResult);
              } else {
                pagelessRoute.markForComplete(
                  pagelessRoute.route.currentResult,
                );
              }
            }
          }
        }
      }
      results.add(exitingPageRoute);
      handleExitingRoute(exitingPageRoute, isLast);
    }

    handleExitingRoute(null, newPageRouteHistory.isEmpty);

    for (final pageRoute in newPageRouteHistory) {
      final isLastIteration = newPageRouteHistory.last == pageRoute;
      if (pageRoute.isWaitingForEnteringDecision) {
        if (!locationToExitingPageRoute.containsKey(pageRoute) &&
            isLastIteration &&
            showAnimation(pageRoute, locationToExitingPageRoute)) {
          pageRoute.markForPush();
        } else {
          pageRoute.markForAdd();
        }
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute, isLastIteration);
    }
    return results;
  }

  bool showAnimation(
    RouteTransitionRecord pageRoute,
    Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
  ) {
    final routes =
        {
              pageRoute,
              ...locationToExitingPageRoute.keys,
              ...locationToExitingPageRoute.values,
            }
            .map((e) => e?.route.settings.name)
            .where((element) => element != null)
            .toSet();
    return !setEquals(routeWithoutAnimation, routes);
  }
}
