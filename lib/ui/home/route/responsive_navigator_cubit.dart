import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/home/route/responsive_navigator.dart';
import 'package:flutter_app/ui/setting/edit_profile_page.dart';
import 'package:flutter_app/ui/setting/notification_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

part 'responsive_navigator_state.dart';

class ResponsiveNavigatorCubit extends AbstractResponsiveNavigatorCubit {
  ResponsiveNavigatorCubit() : super(const ResponsiveNavigatorState());

  static ResponsiveNavigatorCubit of(BuildContext context) =>
      BlocProvider.of<ResponsiveNavigatorCubit>(context);

  final _chatPageKey = GlobalKey();

  static const chatPage = 'chatPage';
  static const editProfilePage = 'editProfilePage';
  static const notificationPage = 'notificationPage';
  static const chatBackupPage = 'chatBackupPage';
  static const dataAndStorageUsagePage = 'dataAndStorageUsagePage';
  static const appearancePage = 'appearancePage';
  static const aboutPage = 'aboutPage';

  static const settingTitlePageMap = {
    editProfilePage,
    notificationPage,
    chatBackupPage,
    dataAndStorageUsagePage,
    appearancePage,
     aboutPage,
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
        return MaterialPage(
          key: const ValueKey(editProfilePage),
          name: editProfilePage,
          child: EditProfilePage(),
        );
      case notificationPage:
        return MaterialPage(
          key: const ValueKey(notificationPage),
          name: notificationPage,
          child: NotificationPage(),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }
}
