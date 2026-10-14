import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';

import 'chat_timeline_fixture.dart';

// Run with: flutter drive --profile -d macos \
//   --driver test_driver/perf_driver.dart \
//   --target integration_test/chat_timeline_perf_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final clock = Stopwatch()..start();
  void step(String name) => debugPrint('[bench] ${clock.elapsed} $name');

  // pumpAndSettle never returns while an animation repeats, so pump a fixed
  // number of real frames instead.
  Future<void> frames(WidgetTester tester, [int count = 60]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  // Animations that still tick after the timeline has been idle for 2 s.
  Future<void> reportIdle(WidgetTester tester, String key) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    binding.reportData ??= {};
    binding.reportData!['${key}_idle_transient_callbacks'] =
        SchedulerBinding.instance.transientCallbackCount;
    step(
      '$key idle transient callbacks: '
      '${SchedulerBinding.instance.transientCallbackCount}',
    );
  }

  setUpAll(() async {
    EventBus.initialize();
    // The macOS runner starts with a hidden window, and a hidden window gets
    // no frames. The app's main() shows it; this test does not run main().
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(size: Size(1000, 800)),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  });

  // TRACE=true records a timeline with one event per widget build instead of
  // frame timings, to find which widgets cost the most.
  const trace = bool.fromEnvironment('TRACE');

  Future<void> measure(String key, Future<void> Function() action) async {
    if (!trace) {
      // watchPerformance counts misses against 16 ms; the target is 120 Hz.
      final timings = <FrameTiming>[];
      void collect(List<FrameTiming> batch) => timings.addAll(batch);
      SchedulerBinding.instance.addTimingsCallback(collect);
      await binding.watchPerformance(action, reportKey: key);
      SchedulerBinding.instance.removeTimingsCallback(collect);
      const budget = Duration(microseconds: 8333);
      final summary = {
        ...?binding.reportData?[key] as Map<String, dynamic>?,
        'frames_120hz': timings.length,
        'build_over_120hz': timings
            .where((t) => t.buildDuration > budget)
            .length,
        'raster_over_120hz': timings
            .where((t) => t.rasterDuration > budget)
            .length,
      };
      binding.reportData![key] = summary;
      step('$key ${jsonEncode(summary)}');
      return;
    }
    debugProfileBuildsEnabledUserWidgets = true;
    debugProfileLayoutsEnabled = true;
    try {
      await binding.traceAction(action, reportKey: '${key}_timeline');
    } finally {
      debugProfileBuildsEnabledUserWidgets = false;
      debugProfileLayoutsEnabled = false;
    }
    step('$key traced');
  }

  testWidgets('chat timeline frame timings', (tester) async {
    step('start');
    final directory = Directory.systemTemp.createTempSync('chat-bench');
    final imagePath = await createLargeImage(directory);
    final messages = buildMessages(
      1200,
      imagePath: imagePath,
      withImages: const bool.fromEnvironment('BENCH_IMAGES'),
    );
    // Mount the app shell once with a warm-up chat, then measure switching to
    // another chat, like the real chat page: fonts and the shell are already
    // built when a chat opens.
    final controller = FakeMessageController(messages.sublist(0, 200));
    final width = ValueNotifier<double>(900);
    final blinkNotifier = BlinkNotifier(tester);
    final database = createFixtureDatabase();
    await tester.pumpWidget(
      ValueListenableBuilder<double>(
        valueListenable: width,
        builder: (context, value, _) => ChatTimelineFixture(
          controller: controller,
          blinkNotifier: blinkNotifier,
          database: database,
          width: value,
        ),
      ),
    );
    await frames(tester);
    step(
      'warmed up; semantics enabled: '
      '${SemanticsBinding.instance.semanticsEnabled}',
    );

    await measure('open', () async {
      controller.open(messages.sublist(0, 1150), refreshKey: 'measured');
      await frames(tester);
    });
    expect(find.byType(MessageItemWidget), findsWidgets);
    step('opened');
    await reportIdle(tester, 'open');

    final viewport = find.byType(Scrollable).first;
    final wheel = TestPointer(1, PointerDeviceKind.mouse)
      ..hover(tester.getCenter(viewport));
    await measure('wheel_scroll_back', () async {
      // Desktop users scroll with a wheel or trackpad: one event per 120 Hz
      // frame, 150 px each (18000 px/s), loading pages on the way.
      for (var i = 0; i < (trace ? 240 : 800); i++) {
        await tester.sendEventToBinding(wheel.scroll(const Offset(0, -150)));
        await tester.pump(const Duration(milliseconds: 8));
      }
    });
    step('wheel scrolled');
    await reportIdle(tester, 'wheel_scroll_back');

    await measure('fling_chain', () async {
      // Fling again before the previous fling settles.
      for (var i = 0; i < 20; i++) {
        await tester.fling(viewport, const Offset(0, -800), 12000);
        await frames(tester, 8);
      }
    });
    step('flung');

    await measure('incoming', () async {
      for (final message in messages.sublist(1150)) {
        controller.append(message);
        await frames(tester, 6);
      }
    });
    step('incoming done');

    await measure('resize', () async {
      for (var i = 0; i < 60; i++) {
        width.value = 600 + (i % 30) * 20;
        await tester.pump(const Duration(milliseconds: 16));
      }
    });
    step('resize done');
  });
}
