// Run with: flutter test integration_test/bot_window_test.dart -d <macos|windows|linux>
// The runner's debugProbe and debugMouse exist in debug builds only.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app.dart' show rootRouteObserver;
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/mixin_database.dart' show App;
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_app/utils/local_state_storage.dart';
import 'package:flutter_app/utils/web_view/desktop/bot_window.dart';
import 'package:flutter_app/utils/web_view/desktop/bot_window_popup.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/dialog.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

const _channel = MethodChannel('one.mixin/bot_window');

// Window content coordinates, top-left based, of the 380 × 750 window with a
// 48 title row and no drag strip: `‹` at (12, 12, 24, 24), capsule at
// (286, 8, 88, 32).
const _headerTop = Offset(60, 4);
const _titleRow = Offset(200, 40);
const _back = Offset(24, 24);
const _capsuleClose = Offset(352, 24);
const _capsuleMore = Offset(308, 24);
const _page = Offset(190, 300);
const _capsule = Rect.fromLTWH(286, 8, 88, 32);

// On Wayland the popup view is laid over the page only, under the title bar.
final _popupCoversHeader = !Platform.isLinux;

const _pageTitle = 'Bot window test page';

void main() {
  // Native events must reach the app, not be dropped by the test binding.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized()
          .shouldPropagateDevicePointerEvents =
      true;

  late HttpServer server;
  late String url;
  final events = <PointerEvent>[];

  setUpAll(() async {
    await windowManager.ensureInitialized();
    await windowManager.show();
    final directory = await Directory.systemTemp.createTemp('bot_window_test');
    await LocalStateStorage.init(directory.path);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        if (request.uri.path == '/next') {
          request.response
            ..headers.contentType = ContentType.html
            ..write(
              '<!doctype html><title>${'Long title ' * 20}</title><body></body>',
            );
          await request.response.close();
          return;
        }
        // The head arrives at once, the body only later: the header must
        // take the theme-color while the page is still loading.
        request.response
          ..bufferOutput = false
          ..headers.contentType = ContentType.html
          ..write('''
<!doctype html>
<html><head>
<meta charset="utf-8">
<title>$_pageTitle</title>
<meta name="theme-color" content="#ff8800">
<!-- ${'-' * 1024} -->
</head>
''');
        await request.response.flush();
        await Future<void>.delayed(const Duration(seconds: 3));
        request.response.write(
          '<body style="margin:0;height:100vh;background:#ffffff"></body></html>',
        );
        await request.response.close();
      });
    url = 'http://127.0.0.1:${server.port}/';
    GestureBinding.instance.pointerRouter.addGlobalRoute(events.add);
  });

  tearDownAll(() => server.close(force: true));

  testWidgets('browser window chrome and popup', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      ProviderScope(
        child: BotWindowPopupHost(
          child: MaterialApp(
            navigatorObservers: [rootRouteObserver],
            builder: (context, child) => BrightnessObserver(
              lightThemeData: lightBrightnessThemeData,
              darkThemeData: darkBrightnessThemeData,
              child: child!,
            ),
            localizationsDelegates: const [
              Localization.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [...Localization.delegate.supportedLocales],
            home: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );

    // A test desktop may keep the foreground elsewhere, as Windows does for
    // apps started by a scheduled task; focus is then checked nowhere.
    await windowManager.focus();
    final canFocus = await windowManager.isFocused();
    if (!canFocus) {
      debugPrint('The app cannot take focus here; skipping focus checks.');
    }

    var window = await BotWindow.open(
      context,
      key: 'test',
      url: url,
      title: 'Test',
      app: null,
      appCardData: null,
      conversationId: null,
      version: 'test',
      windows: const WindowsWebviewOptions(),
    );
    var closed = false;
    unawaited(window.webview.onClose.then((_) => closed = true));
    addTearDown(() async {
      if (!closed) await window.webview.close();
    });

    Future<Map<Object?, Object?>> probe(List<Offset> points) async =>
        (await _channel.invokeMapMethod<Object?, Object?>('debugProbe', {
          'browserId': window.webview.id,
          'points': [
            for (final point in points) [point.dx, point.dy],
          ],
        }))!;

    Future<void> mouse(String type, Offset point) =>
        _channel.invokeMethod<void>('debugMouse', {
          'browserId': window.webview.id,
          'type': type,
          'x': point.dx,
          'y': point.dy,
        });

    Future<void> click(Offset point) async {
      await mouse('down', point);
      await mouse('up', point);
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> waitFor(String reason, FutureOr<bool> Function() done) async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!await done()) {
        if (DateTime.now().isAfter(deadline)) fail('Timed out: $reason');
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> expectChrome(int color) async {
      await waitFor(
        'header color ${color.toRadixString(16)}',
        () async => (await probe(const []))['headerColor'] == color,
      );
      final probes = (await probe([_headerTop, _titleRow]))['probes']! as List;
      for (final p in probes) {
        // The capture is display-managed, so allow some drift per channel.
        final drawn = Color((p as Map)['color']! as int);
        final expected = Color(color);
        expect(
          [drawn.r, drawn.g, drawn.b],
          [
            closeTo(expected.r, 0.1),
            closeTo(expected.g, 0.1),
            closeTo(expected.b, 0.1),
          ],
          reason:
              'pixel drawn in the header: ${drawn.toARGB32().toRadixString(16)}',
        );
      }
    }

    // The page's theme-color reaches the whole header before load completes.
    await expectChrome(0xFFFF8800);
    expect(window.webview.navigationState.value.isLoading, true);
    await waitFor(
      'page loaded',
      () => !window.webview.navigationState.value.isLoading,
    );
    await window.webview.evaluateJavaScript('''
document.querySelector('meta[name="theme-color"]').content = '#101010';
''');
    await expectChrome(0xFF101010);

    // getContext follows the window's appearance.
    expect(
      await window.webview.evaluateJavaScript(
        'JSON.parse(MixinContext.getContext()).appearance',
      ),
      context.brightness == Brightness.dark ? 'dark' : 'light',
    );

    // `‹` shows once the page can go back, and goes back. Without it the
    // title row drags the window.
    Future<Object?> hitAtBack() async =>
        (((await probe([_back]))['probes']! as List).single as Map)['hit'];
    expect(await hitAtBack(), 'header');
    await window.webview.launch('${url}next');
    await waitFor(
      'can go back',
      () => window.webview.navigationState.value.canGoBack,
    );
    expect(await hitAtBack(), 'leading');
    // The page's long title truncates; the window keeps its width.
    await waitFor(
      'long title',
      () => window.webview.navigationState.value.title!.startsWith('Long'),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect((await probe(const []))['width'], 380);
    await click(_back);
    await waitFor(
      'went back',
      () =>
          !window.webview.navigationState.value.canGoBack &&
          !window.webview.navigationState.value.isLoading,
    );
    expect(window.webview.navigationState.value.url, url);
    expect(await hitAtBack(), 'header');

    // X11 has no popup view: ••• shows a native menu instead, not driven
    // here.
    final nativeMenu = (await probe(const []))['nativeMenu'] == true;
    if (!nativeMenu) {
      // ••• opens the menu, hanging from the capsule.
      await window.focus();
      await click(_capsuleMore);
      await waitFor('popup shown', () => window.popupVisible.value);
      await tester.pump(const Duration(milliseconds: 400));
      final viewId = BotWindow.popups.value.keys.single;
      final state = await probe([_headerTop, _capsuleClose, _page]);
      expect(state['popupHidden'], false);
      expect(
        [for (final p in state['probes']! as List) (p as Map)['hit']],
        _popupCoversHeader
            ? ['popup', 'popup', 'popup']
            : ['header', 'capsule', 'popup'],
        reason: 'the popup view covers the window',
      );
      // Window content coordinates of the popup view's origin.
      final origin = state['popupOrigin']! as List;
      final popupOrigin = Offset(
        (origin[0]! as num).toDouble(),
        (origin[1]! as num).toDouble(),
      );
      final menu = tester.getRect(
        find
            .ancestor(
              of: find.text(_pageTitle),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(window.popupAnchor, _capsule.shift(-popupOrigin));
      expect(
        menu.top,
        moreOrLessEquals(
          math.max(window.popupAnchor.bottom + 4, 0).toDouble(),
          epsilon: 1,
        ),
      );
      expect(
        menu.right,
        moreOrLessEquals(window.popupAnchor.right, epsilon: 1),
      );

      // Account dialogs move to the main navigator only after the popup closes.
      BuildContext? main;
      Object? hiddenAtHandoff;
      var handedOff = false;
      unawaited(
        window.showMainWindow().then((value) async {
          main = value;
          hiddenAtHandoff = (await probe(const []))['popupHidden'];
          handedOff = true;
        }),
      );
      await waitFor('main window handoff', () => handedOff);
      expect(main, isNotNull);
      expect(hiddenAtHandoff, true);
      if (canFocus) expect(await windowManager.isFocused(), true);
      final mainViewId = View.of(context).viewId;
      final dialog = showMixinDialog<void>(
        context: main!,
        child: const Text('Main window dialog'),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(
        View.of(tester.element(find.text('Main window dialog'))).viewId,
        mainViewId,
      );
      Navigator.of(main!).pop();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await dialog;

      await window.focus();
      await click(_capsuleMore);
      await waitFor('popup shown again', () => window.popupVisible.value);
      await tester.pump(const Duration(milliseconds: 400));

      // Hover reaches the popup view.
      events.clear();
      await mouse('moved', _page);
      await waitFor(
        'hover in view $viewId',
        () => events.any((e) => e is PointerHoverEvent && e.viewId == viewId),
      );

      // A click on the menu stays in the popup.
      final header = tester.getCenter(find.text(_pageTitle));
      events.clear();
      await click(header + popupOrigin);
      await waitFor(
        'pointer down in view $viewId',
        () => events.any((e) => e is PointerDownEvent && e.viewId == viewId),
      );
      expect(
        events.whereType<PointerDownEvent>().single.position,
        within(distance: 1, from: header),
      );
      expect(window.popupVisible.value, true);

      // A click on the capsule's ✕ hits the barrier: the popup closes, the
      // window does not.
      await click(_capsuleClose);
      await waitFor(
        'popup hidden',
        () async => (await probe(const []))['popupHidden'] == true,
      );
      expect(closed, false);
    }

    // With the popup gone, ✕ closes the window.
    await click(_capsuleClose);
    await waitFor('window closed', () => closed);

    // A bot's title row: its icon fills the 24pt slot before the name, and
    // turns into `‹` once the page can go back.
    window = await BotWindow.open(
      context,
      key: 'bot',
      url: url,
      title: 'Bot',
      app: const App(
        appId: '00000000-0000-0000-0000-000000000001',
        appNumber: '7000000001',
        homeUri: '',
        redirectUri: '',
        name: 'Bot',
        iconUrl: '',
        description: '',
        appSecret: '',
        creatorId: '',
      ),
      appCardData: null,
      conversationId: null,
      version: 'test',
      windows: const WindowsWebviewOptions(),
    );
    closed = false;
    unawaited(window.webview.onClose.then((_) => closed = true));
    Future<Map<Object?, Object?>> leading() async =>
        (await probe(const []))['leading']! as Map<Object?, Object?>;
    expect(await leading(), containsPair('shown', true));
    // The icon drags the window like the rest of the title row.
    expect(await hitAtBack(), 'header');

    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const Color(0xFFFF0000), BlendMode.src);
    final source = await recorder.endRecording().toImage(128, 128);
    final png = (await source.toByteData(format: ui.ImageByteFormat.png))!;
    await window.showIcon(png.buffer.asUint8List());
    await waitFor('icon set', () async => (await leading())['hasIcon'] == true);
    await tester.pump(const Duration(milliseconds: 100));
    final iconPixel = Color(
      (((await probe([_back]))['probes']! as List).single as Map)['color']!
          as int,
    );
    expect(
      [iconPixel.r, iconPixel.g, iconPixel.b],
      [closeTo(1, 0.1), closeTo(0, 0.15), closeTo(0, 0.15)],
      reason: 'icon pixel: ${iconPixel.toARGB32().toRadixString(16)}',
    );

    await window.webview.launch('${url}next');
    await waitFor(
      'bot can go back',
      () => window.webview.navigationState.value.canGoBack,
    );
    await waitFor('‹ shown', () async => (await leading())['back'] == true);
    expect(await hitAtBack(), 'leading');
    await click(_capsuleClose);
    await waitFor('bot window closed', () => closed);
  });
}
