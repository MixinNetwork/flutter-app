import 'package:dio/dio.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/app_update_item.dart';
import 'package:flutter_app/ui/provider/app_update_provider.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _FakeUpdater extends AppUpdateNotifier {
  _FakeUpdater(super.ref, AppUpdateState initial)
    : super.test(package: 'tar-x64', publicKey: const [], dio: Dio.new) {
    state = initial;
  }

  int updates = 0;

  @override
  Future<void> update() async => updates++;
}

void main() {
  late _FakeUpdater updater;

  Future<void> pump(
    WidgetTester tester,
    AppUpdateState state, {
    Widget child = const AppUpdateItem(),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateProvider.overrideWith(
            (ref) => updater = _FakeUpdater(ref, state),
          ),
        ],
        child: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: Portal(
            child: MaterialApp(
              localizationsDelegates: const [Localization.delegate],
              home: Scaffold(body: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows nothing without an update', (tester) async {
    await pump(tester, AppUpdateState.none);
    expect(find.text('Upgrade'), findsNothing);
  });

  testWidgets('a tap on the item installs the update', (tester) async {
    await pump(tester, const AppUpdateState(AppUpdateStatus.available));
    await tester.tap(find.text('Upgrade'));
    expect(updater.updates, 1);
  });

  testWidgets('shows the download progress and ignores taps', (tester) async {
    await pump(
      tester,
      const AppUpdateState(AppUpdateStatus.downloading, progress: 0.42),
    );
    expect(find.text('Upgrade 42%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Upgrade 42%'));
    expect(updater.updates, 0);
  });

  testWidgets('a failed update can be retried', (tester) async {
    await pump(tester, const AppUpdateState(AppUpdateStatus.failed));
    await tester.tap(find.text('Retry'));
    expect(updater.updates, 1);
  });

  group('AppUpdateButton on the forced update page', () {
    late int opened;
    Widget button() => AppUpdateButton(onNoUpdate: () => opened++);
    setUp(() => opened = 0);

    testWidgets('opens the download page without an update', (tester) async {
      await pump(tester, AppUpdateState.none, child: button());
      await tester.tap(find.text('Upgrade'));
      expect(opened, 1);
      expect(updater.updates, 0);
    });

    testWidgets('installs the update in the app', (tester) async {
      await pump(
        tester,
        const AppUpdateState(AppUpdateStatus.available),
        child: button(),
      );
      await tester.tap(find.text('Upgrade'));
      expect(updater.updates, 1);
      expect(opened, 0);
    });

    testWidgets('shows the progress and ignores taps', (tester) async {
      await pump(
        tester,
        const AppUpdateState(AppUpdateStatus.downloading, progress: 0.42),
        child: button(),
      );
      await tester.tap(find.text('Upgrade 42%'));
      expect(updater.updates, 0);
      expect(opened, 0);
    });

    testWidgets('retries a failed update', (tester) async {
      await pump(
        tester,
        const AppUpdateState(AppUpdateStatus.failed),
        child: button(),
      );
      await tester.tap(find.text('Retry'));
      expect(updater.updates, 1);
      expect(opened, 0);
    });

    testWidgets('offers the download page with an update', (tester) async {
      await pump(
        tester,
        const AppUpdateState(AppUpdateStatus.available),
        child: button(),
      );
      await tester.tap(find.text('Download'));
      expect(opened, 1);
      expect(updater.updates, 0);
    });

    testWidgets('keeps the download page after a failure', (tester) async {
      await pump(
        tester,
        const AppUpdateState(AppUpdateStatus.failed),
        child: button(),
      );
      await tester.tap(find.text('Download'));
      expect(opened, 1);
      expect(updater.updates, 0);
    });
  });
}
