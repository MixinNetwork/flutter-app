import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/chat_page.dart';
import 'package:flutter_app/ui/setting/edit_profile_page.dart';
import 'package:flutter_app/ui/setting/notification_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tuple/tuple.dart';

part 'responsive_navigator_state.dart';

class ResponsiveNavigatorCubit extends Cubit<ResponsiveNavigatorState> {
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
    'Edit Profile': editProfilePage,
    'Notification': notificationPage,
    'Chat Backup': chatBackupPage,
    'Data and Storage Usage': dataAndStorageUsagePage,
    'Appearance': appearancePage,
    'About': aboutPage,
  };

  MaterialPage _route(String name, Object arguments) {
    switch (name) {
      case chatPage:
        return MaterialPage(
          key: const Key(chatPage),
          name: chatPage,
          child: ChatPage(
            key: _chatPageKey,
          ),
        );
      case editProfilePage:
        return MaterialPage(
          key: const Key(editProfilePage),
          name: editProfilePage,
          child: EditProfilePage(),
        );
      case notificationPage:
        return MaterialPage(
          key: const Key(notificationPage),
          name: notificationPage,
          child: NotificationPage(),
        );
      default:
        throw ArgumentError('Invalid route');
    }
  }

  void updateNavigationMode(bool navigationMode) =>
      emit(state.copyWith(navigationMode: navigationMode));

  void onPopPage() {
    final bool = state.pages.isNotEmpty == true;
    if (bool)
      emit(state.copyWith(
        pages: state.pages.toList()..removeLast(),
      ));
  }

  void pushPage(String name, {Object arguments}) {
    final page = _route(name, arguments);
    var index = -1;
    index = state.pages
        .indexWhere((element) => element.child.key == page.child.key);
    if (state.pages.isNotEmpty && index == state.pages.length - 1) return;
    if (index != -1) state.pages.removeRange(max(index, 0), state.pages.length);
    emit(state.copyWith(
      pages: state.pages.toList()..add(page),
    ));
  }

  void popWhere(bool Function(MaterialPage page) test) => emit(state.copyWith(
        pages: state.pages.toList()..removeWhere(test),
      ));
}
