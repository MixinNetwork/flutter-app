import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const initializationSettingsMacOS = MacOSInitializationSettings();
const initializationSettings =
    InitializationSettings(macOS: initializationSettingsMacOS);

enum NotificationScheme {
  conversation,
}

class LocalNotificationCenter {
  static final StreamController<Uri> _payloadStreamController =
      StreamController<Uri>.broadcast();
  static var _id = 0;
  static var initialed = false;

  static Future<void> initListener() async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
    await flutterLocalNotificationsPlugin.cancelAll();
    _id = 0;
    initialed = true;
  }

  static Future<dynamic> _onSelectNotification(String? payload) async {
    if (payload?.isEmpty ?? true) return;
    try {
      _payloadStreamController.add(Uri.parse(payload!));
    } catch (_) {}
  }

  static Stream<Uri> notificationSelectEvent(
          NotificationScheme notificationScheme) =>
      _payloadStreamController.stream.where((e) =>
          e.scheme.toUpperCase() ==
          EnumToString.convertToString(notificationScheme));

  static Future<void> showNotification({
    required String title,
    required String body,
    required Uri uri,
  }) async {
    await _requestPermission();

    // TODO Set mixin.caf to be invalid.
    const platformChannelSpecifics = NotificationDetails(
      macOS: MacOSNotificationDetails(sound: 'mixin.caf'),
    );
    await flutterLocalNotificationsPlugin.show(
      _id++,
      title,
      body,
      platformChannelSpecifics,
      payload: uri.toString(),
    );
  }

  static Future<bool?>? _requestPermission() => flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}
