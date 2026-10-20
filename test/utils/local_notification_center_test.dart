import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/local_notification_center.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Implements instead of extends: the real constructor loads Linux-only FFI.
class _FakeLinuxNotifications
    with MockPlatformInterfaceMixin
    implements LinuxFlutterLocalNotificationsPlugin {
  final shown = <(int, String?, LinuxNotificationDetails?)>[];

  @override
  Future<bool?> initialize({
    required LinuxInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async => true;

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    LinuxNotificationDetails? notificationDetails,
    String? payload,
  }) async => shown.add((id, body, notificationDetails));

  @override
  Future<void> cancel({required int id}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _show(String conversationId, String messageId) => showNotification(
  title: 'title',
  body: messageId,
  uri: Uri(scheme: 'conversation', host: conversationId, path: messageId),
  conversationId: conversationId,
  messageId: messageId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Linux replaces the previous notification of a conversation', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final plugin = _FakeLinuxNotifications();
    FlutterLocalNotificationsPlatform.instance = plugin;
    await initListener();

    await _show('a', 'm1');
    await _show('a', 'm2');
    await _show('b', 'm3');

    final [(first, _, details), (second, body, _), (other, _, _)] =
        plugin.shown;
    expect(second, first);
    expect(body, 'm2');
    expect(other, isNot(first));
    expect(details?.category, LinuxNotificationCategory.imReceived);
  });
}
