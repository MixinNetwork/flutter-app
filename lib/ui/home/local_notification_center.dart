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
  LocalNotificationCenter() {
    _init();
  }

  final StreamController<Uri> payloadStreamController =
      StreamController<Uri>.broadcast();
  var _id = 0;

  Future<void> _init() async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
    await flutterLocalNotificationsPlugin.cancelAll();
    _id = 0;
  }

  Future<void> dispose() => payloadStreamController.close();

  Future<dynamic> _onSelectNotification(String? payload) async {
    if (payload?.isEmpty ?? true) return;
    try {
      payloadStreamController.add(Uri.parse(payload!));
    } catch (_) {}
  }

  Stream<Uri> notificationSelectEvent(NotificationScheme notificationScheme) =>
      payloadStreamController.stream
          .where((e) =>
              e.scheme.toUpperCase() ==
              EnumToString.convertToString(notificationScheme))
          .distinct();

  /// example:
  ///   context.read<LocalNotificationCenter>().showNotification(
  //         title: 'title',
  //         body: text,
  //         uri: Uri(
  //           scheme: EnumToString.convertToString(NotificationScheme.conversation),
  //           host: conversationId,
  //         ),
  //       );
  Future<void> showNotification({
    required String title,
    required String body,
    Uri? uri,
  }) async {
    await _requestPermission();

    const platformChannelSpecifics = NotificationDetails(
      macOS: MacOSNotificationDetails(
          // TODO
          //   sound:
          ),
    );
    await flutterLocalNotificationsPlugin.show(
      _id++,
      title,
      body,
      platformChannelSpecifics,
      payload: uri?.toString(),
    );
  }

  Future<void> _requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}
