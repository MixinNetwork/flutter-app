import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/utils/local_notification_center.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dismissAllNotifications cancels every shown notification', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    FlutterLocalNotificationsPlatform.instance =
        MacOSFlutterLocalNotificationsPlugin();
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (call) async {
            calls.add(call.method);
            return call.method == 'initialize' ? true : null;
          },
        );

    await initListener();
    await showNotification(
      title: 'title',
      uri: Uri(scheme: 'conversation', host: 'a', path: 'm1'),
      conversationId: 'a',
      messageId: 'm1',
    );
    calls.clear();

    await dismissAllNotifications();

    expect(calls, ['cancelAll']);
  });
}
