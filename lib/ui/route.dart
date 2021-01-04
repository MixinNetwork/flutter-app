import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/setting/edit_profile_page.dart';
import 'package:flutter_app/ui/setting/notification_page.dart';
import 'package:flutter_app/widgets/responsive_navigator.dart';

class MixinRouter {
  MixinRouter._();

  static final MixinRouter instance = MixinRouter._();

  final _chatPageKey = GlobalKey();
  final chatResponsiveNavigation = GlobalKey<ResponsiveNavigatorState>();

  static const chatPage = 'chatPage';
  static const editProfilePage = 'editProfilePage';
  static const notificationPage = 'notificationPage';
  static const chatBackupPage = 'chatBackupPage';
  static const dataAndStorageUsagePage = 'dataAndStorageUsagePage';
  static const appearancePage = 'appearancePage';
  static const aboutPage = 'aboutPage';

  static const settingPrefix = 'settingPrefix_';

  MaterialPage route(String name, Object arguments) {
    switch (name) {
      case chatPage:
        return MaterialPage(
          key: const Key(chatPage),
          name: chatPage,
          child: ChatPage(key: _chatPageKey),
        );
      case editProfilePage:
        return MaterialPage(
          key: const Key('$settingPrefix$editProfilePage'),
          name: editProfilePage,
          child: EditProfilePage(),
        );
      case notificationPage:
        return MaterialPage(
          key: const Key('$settingPrefix$notificationPage'),
          name: notificationPage,
          child: NotificationPage(),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }

  void pushPage(String name, {Object arguments}) =>
      chatResponsiveNavigation.currentState
          ?.pushPage(name, arguments: arguments);

  void popWhere(bool Function(MaterialPage page) test) =>
      chatResponsiveNavigation.currentState?.popWhere(test);

  bool get navigationMode =>
      chatResponsiveNavigation.currentState?.navigationMode;
}
