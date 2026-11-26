import 'dart:io';

import 'package:flutter_app/account/account_server.dart';
import 'package:flutter_app/account/security_key_value.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/provider/account_server_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/widgets/auth.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/protocol_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('the app counts as locked each time the lock screen shows', (
    tester,
  ) async {
    EventBus.initialize();
    final security = SecurityKeyValue.instance;
    late Directory directory;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('app_locked');
      mixinDocumentsDirectory = directory;
      await security.init('1000');
      // The stored key, so that the test does not depend on how it is set.
      await security.box.put('passcode', '739142');
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountServerProvider.overrideWith((ref) => _ReadyAccountServer()),
        ],
        child: const BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: MaterialApp(
            localizationsDelegates: [Localization.delegate],
            home: AuthGuard(child: SizedBox()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final opened = <String>[];
    Future<void> openLink() => openExternalUri(
      tester.element(find.byType(AuthGuard)),
      'mixin://send',
      open: (context, url, {required confirmSend}) async {
        opened.add(url);
        return true;
      },
    );

    Future<void> send(LockEvent event) async {
      EventBus.instance.fire(event);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
    }

    for (var round = 1; round <= 2; round++) {
      expect(find.byType(EditableText), findsOneWidget, reason: '$round');
      expect(appLocked.value, isTrue, reason: 'locked, round $round');
      await openLink();
      expect(opened, isEmpty, reason: 'locked, round $round');

      await send(LockEvent.unlock);
      expect(find.byType(EditableText), findsNothing);
      expect(appLocked.value, isFalse, reason: 'unlocked, round $round');

      await send(LockEvent.lock);
    }

    // Without the guard there is no lock screen.
    await tester.pumpWidget(const SizedBox());
    expect(appLocked.value, isFalse);

    await tester.runAsync(() async {
      await security.delete();
      await Hive.close();
      await directory.delete(recursive: true);
    });
  });
}

class _ReadyAccountServer extends AccountServerOpener {
  _ReadyAccountServer() {
    state = AsyncValue.data(_FakeAccountServer());
  }
}

class _FakeAccountServer implements AccountServer {
  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
