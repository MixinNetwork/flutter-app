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
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('only the passcode unlocks the app', (tester) async {
    EventBus.initialize();
    final security = SecurityKeyValue.instance;
    late Directory directory;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('lock_screen');
      mixinDocumentsDirectory = directory;
      await security.init('1000');
      await security.setPasscode('739142');
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
    expect(appLocked.value, isTrue);

    // The passcode is checked on another isolate, which needs real time.
    Future<void> enter(String code, bool Function() checked) async {
      await tester.enterText(find.byType(EditableText), code);
      for (var i = 0; i < 600 && !checked(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    final error = find.text(Localization.current.passcodeIncorrect);

    await enter('000000', () => error.hitTestable().evaluate().isNotEmpty);
    expect(appLocked.value, isTrue);
    expect(error.hitTestable(), findsOneWidget);

    await enter('739142', () => !appLocked.value);
    expect(appLocked.value, isFalse);
    expect(find.byType(EditableText), findsNothing);

    Future<void> lockAgain() async {
      EventBus.instance.fire(LockEvent.lock);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
    }

    // A wrong passcode is still being checked when the right one is entered.
    await lockAgain();
    await tester.enterText(find.byType(EditableText), '000000');
    await tester.pump();
    await enter('739142', () => !appLocked.value);
    // Gives the other check the time to end too.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 5)),
    );
    await tester.pumpAndSettle();
    expect(appLocked.value, isFalse);

    await lockAgain();
    expect(find.byType(EditableText), findsOneWidget);
    expect(error.hitTestable(), findsNothing);

    // A check started before an unlock and relock must not unlock the new lock.
    await tester.enterText(find.byType(EditableText), '739142');
    await tester.pump();
    EventBus.instance.fire(LockEvent.unlock);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    expect(appLocked.value, isFalse);
    await lockAgain();
    expect(appLocked.value, isTrue);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();
    expect(appLocked.value, isTrue);

    await tester.pumpWidget(const SizedBox());
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
