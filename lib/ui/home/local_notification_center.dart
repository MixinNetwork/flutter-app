import 'dart:async';
import 'dart:io';

import 'package:desktop_notifications/desktop_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../../utils/logger.dart';

abstract class _NotificationManager {
  final StreamController<Uri> _payloadStreamController =
      StreamController<Uri>.broadcast();

  Future<void> initialize();

  Future<void> showNotification({
    required String title,
    String? body,
    required Uri uri,
    required int id,
  });

  @protected
  void onNotificationSelected(Uri uri) => _payloadStreamController.add(uri);

  Stream<Uri> notificationActionEvent(NotificationScheme notificationScheme) =>
      _payloadStreamController.stream.where(
          (e) => e.scheme == EnumToString.convertToString(notificationScheme));
}

class _MacosNotificationManager extends _NotificationManager {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    const initializationSettingsMacOS = MacOSInitializationSettings();
    const initializationSettings =
        InitializationSettings(macOS: initializationSettingsMacOS);
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
  }) async {
    await _requestPermission();
    // TODO Set mixin.caf to be invalid.
    const platformChannelSpecifics = NotificationDetails(
      macOS: MacOSNotificationDetails(sound: 'mixin.caf'),
    );
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: uri.toString(),
    );
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
    onNotificationSelected(uri);
  }
}

class _LinuxNotificationManager extends _NotificationManager {
  // default action key. https://developer.gnome.org/notification-spec/
  static const kDefaultAction = 'default';

  final _client = NotificationsClient();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showNotification({
    required String title,
    String? body,
    required Uri uri,
    required int id,
  }) async {
    i('show linux notification: $title $body');
    final notification = await _client.notify(title,
        body: body ?? '',
        replacesId: id,
        expireTimeoutMs: 0,
        appName: 'Mixin',
        hints: [
          NotificationHint.category(NotificationCategory.im()),
          NotificationHint.resident(),
          NotificationHint.transient(),
        ],
        actions: const [
          NotificationAction(kDefaultAction, ''),
        ]);

    unawaited(notification.action.then((action) async {
      if (action != kDefaultAction) return;
      onNotificationSelected(uri);
      await notification.close();
    }));
  }
}

enum NotificationScheme {
  conversation,
}

_NotificationManager? _notificationManager;
int _id = 0;

Future<void> initListener() async {
  _id = 0;
  if (Platform.isMacOS) {
    _notificationManager = _MacosNotificationManager();
  } else if (Platform.isLinux) {
    _notificationManager = _LinuxNotificationManager();
  } else {
    e('notification unsupported for platform: ${Platform.operatingSystem}');
  }
  await _notificationManager?.initialize();
}

Stream<Uri> notificationSelectEvent(NotificationScheme notificationScheme) =>
    _notificationManager?.notificationActionEvent(notificationScheme) ??
    const Stream.empty();

Future<void> showNotification({
  required String title,
  String? body,
  required Uri uri,
}) async {
  if (_notificationManager == null) return;
  await _notificationManager!.showNotification(
    title: title,
    uri: uri,
    id: _id,
    body: body,
  );
}
