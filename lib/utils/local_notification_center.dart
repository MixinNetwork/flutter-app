import 'dart:async';
import 'dart:io';

import 'package:bring_window_to_front/bring_window_to_front.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';

import 'package:win_toast/win_toast.dart';
import 'package:window_manager/window_manager.dart';

import '../constants/resources.dart';
import 'logger.dart';

class Notification {
  Notification({
    required this.conversationId,
    required this.messageId,
    required this.notification,
  });

  final String conversationId;
  final String messageId;
  final dynamic notification;
}

abstract class _NotificationManager {
  final _payloadStreamController = BehaviorSubject<Uri>();
  final List<Notification> notifications = [];

  Future<void> initialize();

  Future<void> showNotification({
    required String title,
    String? body,
    required Uri uri,
    required int id,
    required String conversationId,
    required String messageId,
  });

  Future<void> dismissByConversationId(String conversationId);

  Future<void> dismissByMessageId(String messageId, String conversationId);

  Future<void> dismissAll();

  Future<bool?> requestPermission();

  @protected
  void onNotificationSelected(Uri uri) => _payloadStreamController.add(uri);

  Stream<Uri> notificationActionEvent(NotificationScheme notificationScheme) =>
      _payloadStreamController.stream
          .where((e) => e.scheme == enumConvertToString(notificationScheme));
}

// Implement by FlutterLocalNotificationsPlugin.
// Platforms: Linux, Android, macOS, iOS.
class _LocalNotificationManager extends _NotificationManager {
  // default action key. https://developer.gnome.org/notification-spec/
  static const kDefaultAction = 'default';

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    final darwinInitializationSettings = DarwinInitializationSettings(
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) {
      i('onDidReceiveLocalNotification: $id');
    });

    final initializationSettings = InitializationSettings(
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings,
      linux: LinuxInitializationSettings(
        defaultActionName: kDefaultAction,
        defaultIcon: AssetsLinuxIcon(Resources.assetsIconsMacosAppIconPng),
        defaultSound: ThemeLinuxSound('message'),
      ),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification);
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<void> showNotification({
    required String title,
    String? body,
    required Uri uri,
    required int id,
    required String conversationId,
    required String messageId,
  }) async {
    await requestPermission();

    const notificationDetails = DarwinNotificationDetails(
      sound: 'mixin.caf',
      presentSound: true,
    );

    const platformChannelSpecifics = NotificationDetails(
      macOS: notificationDetails,
      iOS: notificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: uri.toString(),
    );
    notifications.add(Notification(
      conversationId: conversationId,
      messageId: messageId,
      notification: (uri, id),
    ));
  }

  @override
  Future<bool?> requestPermission() async => flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  Future<dynamic> _onSelectNotification(NotificationResponse details) async {
    final payload = details.payload;
    if (payload?.isEmpty ?? true) return;
    final uri = Uri.tryParse(payload!);
    if (uri == null) return;

    final notification = notifications.cast<Notification?>().firstWhere(
        (element) =>
            element != null && (element.notification as (Uri, int)).$1 == uri,
        orElse: () => null);
    if (notification != null) notifications.remove(notification);

    if (Platform.isLinux) {
      unawaited(bringWindowToFront());
    }

    onNotificationSelected(uri);
  }

  @override
  Future<void> dismissByConversationId(String conversationId) async {
    final list = await Future.wait(notifications
        .where((element) => element.conversationId == conversationId)
        .map((e) async {
      final (_, id) = e.notification as (Uri, int);
      await flutterLocalNotificationsPlugin.cancel(id);
      return e;
    }));
    return list.forEach(notifications.remove);
  }

  @override
  Future<void> dismissByMessageId(
      String messageId, String conversationId) async {
    final notification = notifications.cast<Notification?>().firstWhere(
        (element) => element?.messageId == messageId,
        orElse: () => null);
    if (notification == null) return;
    final (_, id) = notification.notification as (Uri, int);
    await flutterLocalNotificationsPlugin.cancel(id);
    notifications.remove(notification);
  }

  @override
  Future<void> dismissAll() => flutterLocalNotificationsPlugin.cancelAll();
}

class _WindowsNotificationManager extends _NotificationManager {
  @override
  Future<void> initialize() async {
    WinToast.instance().setActivatedCallback(_handleToastActivated);
    await WinToast.instance().initialize(
      aumId: '14801MixinLtd.MixinDesktop',
      displayName: 'Mixin Messenger',
      iconPath: '',
      clsid: '94B64592-528D-48B4-B37B-C82D634F1BE7',
    );
  }

  void _handleToastActivated(ActivatedEvent event) {
    final params = Uri.splitQueryString(event.argument);
    d('win toast activated: $params');
    final uri = Uri.tryParse(params['uri'] ?? '');
    if (uri == null) {
      return;
    }
    windowManager.show(inactive: true);
    onNotificationSelected(uri);
  }

  @override
  Future<void> showNotification({
    required String title,
    String? body,
    required Uri uri,
    required int id,
    required String conversationId,
    required String messageId,
  }) async {
    await WinToast.instance().showToast(
      toast: Toast(
        duration: ToastDuration.short,
        launch: 'uri=$uri',
        children: [
          ToastChildVisual(
            binding: ToastVisualBinding(
              children: [
                ToastVisualBindingChildText(text: title, id: 1),
                ToastVisualBindingChildText(text: body ?? '', id: 2),
              ],
            ),
          )
        ],
      ),
      tag: messageId,
      group: conversationId,
    );
  }

  @override
  Future<void> dismissByConversationId(String conversationId) async {
    await WinToast.instance().dismiss(tag: '', group: conversationId);
  }

  @override
  Future<void> dismissByMessageId(
    String messageId,
    String conversationId,
  ) async {
    await WinToast.instance().dismiss(
      tag: messageId,
      group: conversationId,
    );
  }

  @override
  Future<bool?> requestPermission() async => null;

  @override
  Future<void> dismissAll() => WinToast.instance().clear();
}

enum NotificationScheme {
  conversation,
}

_NotificationManager? _notificationManager;
int _id = 0;

Future<void> initListener() async {
  _id = 0;
  if (Platform.isMacOS || Platform.isIOS || Platform.isLinux) {
    _notificationManager = _LocalNotificationManager();
  } else if (Platform.isWindows) {
    _notificationManager = _WindowsNotificationManager();
  } else {
    e('notification unsupported for platform: ${Platform.operatingSystem}');
  }
  try {
    await _notificationManager?.initialize();
  } catch (error, s) {
    e('notification manager initialize failed: $error $s');
  }
}

Stream<Uri> notificationSelectEvent(NotificationScheme notificationScheme) =>
    _notificationManager?.notificationActionEvent(notificationScheme) ??
    const Stream.empty();

int _incrementAndGetId() {
  _id++;
  // id should be fit within the size of a 32-bit integer in flutter_local_notifications.
  if (_id > 0x7FFFFFFF) {
    _id = 0;
  }
  return _id;
}

Future<void> showNotification({
  required String title,
  String? body,
  required Uri uri,
  required String conversationId,
  required String messageId,
}) async =>
    await _notificationManager?.showNotification(
      title: title,
      uri: uri,
      id: _incrementAndGetId(),
      body: body,
      conversationId: conversationId,
      messageId: messageId,
    );

Future<void> dismissByConversationId(String conversationId) async =>
    await _notificationManager?.dismissByConversationId(conversationId);

Future<void> dismissByMessageId(
        String messageId, String conversationId) async =>
    await _notificationManager?.dismissByMessageId(messageId, conversationId);

Future<bool?> requestNotificationPermission() async =>
    _notificationManager?.requestPermission();
