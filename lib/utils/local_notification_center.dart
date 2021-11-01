import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:tuple/tuple.dart';
import 'package:win_toast/win_toast.dart' as win;

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
  final StreamController<Uri> _payloadStreamController =
      StreamController<Uri>.broadcast();
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

  Future<void> dismissByMessageId(String messageId);

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
    const initializationSettingsMacOS = MacOSInitializationSettings();
    final initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: (
      int id,
      String? title,
      String? body,
      String? payload,
    ) async {
      i('onDidReceiveLocalNotification: $id');
    });
    final initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
      linux: LinuxInitializationSettings(
        defaultActionName: kDefaultAction,
        defaultIcon: AssetsLinuxIcon(Resources.assetsIconsMacosAppIconPng),
        defaultSound: ThemeLinuxSound('message'),
      ),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
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
    await _requestPermission();
    // TODO Set mixin.caf to be invalid.
    const platformChannelSpecifics = NotificationDetails(
      macOS: MacOSNotificationDetails(sound: 'mixin.caf'),
      iOS: IOSNotificationDetails(
        sound: 'mixin.caf',
        presentSound: true,
      ),
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
      notification: Tuple2(uri, id),
    ));
  }

  Future<bool?>? _requestPermission() => flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  Future<dynamic> _onSelectNotification(String? payload) async {
    if (payload?.isEmpty ?? true) return;
    final uri = Uri.tryParse(payload!);
    if (uri == null) return;

    final notification = notifications.cast<Notification?>().firstWhere(
        (element) =>
            element != null &&
            (element.notification as Tuple2<Uri, int>).item1 == uri,
        orElse: () => null);
    if (notification != null) notifications.remove(notification);

    onNotificationSelected(uri);
  }

  @override
  Future<void> dismissByConversationId(String conversationId) async {
    final list = await Future.wait(notifications
        .where((element) => element.conversationId == conversationId)
        .map((e) async {
      final id = (e.notification as Tuple2<Uri, int>).item2;
      await flutterLocalNotificationsPlugin.cancel(id);
      return e;
    }));
    return list.forEach(notifications.remove);
  }

  @override
  Future<void> dismissByMessageId(String messageId) async {
    final notification = notifications.cast<Notification?>().firstWhere(
        (element) => element?.messageId == messageId,
        orElse: () => null);
    if (notification == null) return;
    final id = (notification.notification as Tuple2<Uri, int>).item2;
    await flutterLocalNotificationsPlugin.cancel(id);
    notifications.remove(notification);
  }
}

class _WindowsNotificationManager extends _NotificationManager {
  @override
  Future<void> initialize() async {
    await win.WinToast.instance().initialize(
      appName: 'Mixin',
      productName: 'mixin_desktop',
      companyName: 'mixin',
    );
    await win.WinToast.instance().clear();
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
    final type = body == null || body.isEmpty
        ? win.ToastType.text01
        : win.ToastType.text02;
    final toast = await win.WinToast.instance().showToast(
      type: type,
      title: title,
      subtitle: body ?? '',
    );
    if (toast == null) {
      return;
    }

    final notificationObj = Notification(
        conversationId: conversationId,
        messageId: messageId,
        notification: toast);
    notifications.add(notificationObj);

    toast.eventStream.listen((event) {
      if (event is win.ActivatedEvent) {
        win.WinToast.instance().bringWindowToFront();

        notifications.remove(notificationObj);

        onNotificationSelected(uri);
      }
    });
  }

  @override
  Future<void> dismissByConversationId(String conversationId) async {
    notifications.removeWhere((element) {
      if (element.conversationId == conversationId) {
        (element.notification as win.Toast).dismiss();

        return true;
      }
      return false;
    });
  }

  @override
  Future<void> dismissByMessageId(String messageId) async {
    final notificationObj = notifications.cast<Notification?>().firstWhere(
        (element) => element?.messageId == messageId,
        orElse: () => null);
    if (notificationObj == null) return;
    (notificationObj.notification as win.Toast).dismiss();
    notifications.remove(notificationObj);
  }
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
  await _notificationManager?.initialize();
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

Future<void> dismissByMessageId(String messageId) async =>
    await _notificationManager?.dismissByMessageId(messageId);
