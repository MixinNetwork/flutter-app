import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

import '../../setting/about_page.dart';
import '../../setting/account_delete_page.dart';
import '../../setting/account_page.dart';
import '../../setting/appearance_page.dart';
import '../../setting/backup_page.dart';
import '../../setting/edit_profile_page.dart';
import '../../setting/notification_page.dart';
import '../../setting/proxy_page.dart';
import '../../setting/storage_page.dart';
import '../../setting/storage_usage_detail_page.dart';
import '../../setting/storage_usage_list_page.dart';
import '../chat/chat_page.dart';
import 'responsive_navigator.dart';

part 'responsive_navigator_state.dart';

class ResponsiveNavigatorCubit extends AbstractResponsiveNavigatorCubit {
  ResponsiveNavigatorCubit() : super(const ResponsiveNavigatorState());

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
  };

  @override
  MaterialPage route(String name, Object? arguments) {
    switch (name) {
      case chatPage:
        return MaterialPage(
          key: const ValueKey(chatPage),
          name: chatPage,
          child: ChatPage(
            key: _chatPageKey,
          ),
        );
      case editProfilePage:
        return const MaterialPage(
          key: ValueKey(editProfilePage),
          name: editProfilePage,
          child: EditProfilePage(
            key: ValueKey(editProfilePage),
          ),
        );
      case notificationPage:
        return const MaterialPage(
          key: ValueKey(notificationPage),
          name: notificationPage,
          child: NotificationPage(
            key: ValueKey(notificationPage),
          ),
        );
      case chatBackupPage:
        return const MaterialPage(
          key: ValueKey(chatBackupPage),
          name: chatBackupPage,
          child: BackupPage(
            key: ValueKey(chatBackupPage),
          ),
        );
      case dataAndStorageUsagePage:
        return const MaterialPage(
          key: ValueKey(dataAndStorageUsagePage),
          name: dataAndStorageUsagePage,
          child: StoragePage(
            key: ValueKey(dataAndStorageUsagePage),
          ),
        );
      case aboutPage:
        return const MaterialPage(
          key: ValueKey(aboutPage),
          name: aboutPage,
          child: AboutPage(
            key: ValueKey(aboutPage),
          ),
        );
      case storageUsage:
        return const MaterialPage(
          key: ValueKey(storageUsage),
          name: storageUsage,
          child: StorageUsageListPage(
            key: ValueKey(storageUsage),
          ),
        );
      case storageUsageDetail:
        if (arguments == null || arguments is! Tuple2<String, String>) {
          throw ArgumentError('Invalid route');
        }

        return MaterialPage(
          key: const ValueKey(storageUsageDetail),
          name: storageUsageDetail,
          child: StorageUsageDetailPage(
            key: const ValueKey(storageUsageDetail),
            name: arguments.item1,
            conversationId: arguments.item2,
          ),
        );
      case appearancePage:
        return const MaterialPage(
            key: ValueKey(appearancePage),
            name: appearancePage,
            child: AppearancePage(
              key: ValueKey(appearancePage),
            ));
      case accountPage:
        return const MaterialPage(
          key: ValueKey(accountPage),
          name: accountPage,
          child: AccountPage(
            key: ValueKey(accountPage),
          ),
        );
      case accountDeletePage:
        return const MaterialPage(
          key: ValueKey(accountDeletePage),
          name: accountDeletePage,
          child: AccountDeletePage(
            key: ValueKey(accountDeletePage),
          ),
        );
      case proxyPage:
        return const MaterialPage(
          key: ValueKey(proxyPage),
          name: proxyPage,
          child: ProxyPage(
            key: ValueKey(proxyPage),
          ),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }
}
