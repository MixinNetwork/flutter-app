import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../home/chat/chat_page.dart';
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
import 'abstract_responsive_navigator.dart';

class ResponsiveNavigatorStateNotifier
    extends AbstractResponsiveNavigatorStateNotifier {
  ResponsiveNavigatorStateNotifier() : super(const ResponsiveNavigatorState());

  final _chatPageKey = GlobalKey();

  static const chatPage = 'chatPage';
  static const editProfilePage = 'editProfilePage';
  static const accountPage = 'accountPage';
  static const accountDeletePage = 'accountDeletePage';
  static const storagePage = 'storagePage';
  static const notificationPage = 'notificationPage';
  static const chatBackupPage = 'chatBackupPage';
  static const dataAndStorageUsagePage = 'dataAndStorageUsagePage';
  static const appearancePage = 'appearancePage';
  static const aboutPage = 'aboutPage';
  static const storageUsage = 'storageUsage';
  static const storageUsageDetail = 'storageUsageDetail';
  static const proxyPage = 'proxyPage';
  static const securityPage = 'securityPage';

  static const settingPageNameSet = {
    editProfilePage,
    notificationPage,
    chatBackupPage,
    dataAndStorageUsagePage,
    appearancePage,
    aboutPage,
    storageUsage,
    storageUsageDetail,
    accountPage,
    accountDeletePage,
    proxyPage,
    securityPage,
  };

  @override
  MaterialPage route(String name, Object? arguments) {
    switch (name) {
      case chatPage:
        return MaterialPage(
          key: const ValueKey(chatPage),
          name: chatPage,
          child: ChatPage(key: _chatPageKey),
        );
      case editProfilePage:
        return const MaterialPage(
          key: ValueKey(editProfilePage),
          name: editProfilePage,
          child: EditProfilePage(key: ValueKey(editProfilePage)),
        );
      case notificationPage:
        return const MaterialPage(
          key: ValueKey(notificationPage),
          name: notificationPage,
          child: NotificationPage(key: ValueKey(notificationPage)),
        );
      case chatBackupPage:
        return const MaterialPage(
          key: ValueKey(chatBackupPage),
          name: chatBackupPage,
          child: BackupPage(key: ValueKey(chatBackupPage)),
        );
      case dataAndStorageUsagePage:
        return const MaterialPage(
          key: ValueKey(dataAndStorageUsagePage),
          name: dataAndStorageUsagePage,
          child: StoragePage(key: ValueKey(dataAndStorageUsagePage)),
        );
      case aboutPage:
        return const MaterialPage(
          key: ValueKey(aboutPage),
          name: aboutPage,
          child: AboutPage(key: ValueKey(aboutPage)),
        );
      case storageUsage:
        return const MaterialPage(
          key: ValueKey(storageUsage),
          name: storageUsage,
          child: StorageUsageListPage(key: ValueKey(storageUsage)),
        );
      case storageUsageDetail:
        if (arguments == null || arguments is! (String, String)) {
          throw ArgumentError('Invalid route');
        }

        return MaterialPage(
          key: const ValueKey(storageUsageDetail),
          name: storageUsageDetail,
          child: StorageUsageDetailPage(
            key: const ValueKey(storageUsageDetail),
            name: arguments.$1,
            conversationId: arguments.$2,
          ),
        );
      case appearancePage:
        return const MaterialPage(
            key: ValueKey(appearancePage),
            name: appearancePage,
            child: AppearancePage(key: ValueKey(appearancePage)));
      case accountPage:
        return const MaterialPage(
          key: ValueKey(accountPage),
          name: accountPage,
          child: AccountPage(key: ValueKey(accountPage)),
        );
      case accountDeletePage:
        return const MaterialPage(
          key: ValueKey(accountDeletePage),
          name: accountDeletePage,
          child: AccountDeletePage(key: ValueKey(accountDeletePage)),
        );
      case proxyPage:
        return const MaterialPage(
          key: ValueKey(proxyPage),
          name: proxyPage,
          child: ProxyPage(key: ValueKey(proxyPage)),
        );
      case securityPage:
        return const MaterialPage(
          key: ValueKey(securityPage),
          name: securityPage,
          child: SecurityPage(key: ValueKey(securityPage)),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }
}

final responsiveNavigatorProvider = StateNotifierProvider.autoDispose<
    ResponsiveNavigatorStateNotifier,
    ResponsiveNavigatorState>((ref) => ResponsiveNavigatorStateNotifier());

final navigatorRouteModeProvider =
    responsiveNavigatorProvider.select((value) => value.routeMode);
