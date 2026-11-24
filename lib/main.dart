import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:ansicolor/ansicolor.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isolate/isolate.dart';
import 'package:material_ui/material_ui.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:rhttp/rhttp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'app.dart';
import 'ui/home/desktop_shell_layout.dart';
import 'ui/setting/log_page.dart';
import 'utils/app_lifecycle.dart';
import 'utils/event_bus.dart';
import 'utils/file.dart';
import 'utils/frame_log.dart';
import 'utils/load_balancer_utils.dart';
import 'utils/local_notification_center.dart';
import 'utils/local_state_storage.dart';
import 'utils/logger.dart';
import 'utils/platform.dart';
import 'utils/system/linux_accessibility.dart';
import 'utils/system/main_window.dart';
import 'utils/system/system_fonts.dart';
import 'widgets/high_light_text.dart' show prepareLinkRanges;
import 'widgets/protocol_handler.dart';

Future<void> main(List<String> args) async {
  await _runApp(args);
}

Future<void> _runApp(List<String> args) async {
  // The first binding wins, so create it before anything else needs one.
  if (Platform.isLinux) LinuxSemanticsBinding();
  EquatableConfig.stringify = true;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  await Rhttp.init();

  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) unawaited(watchLinuxAccessibility());
  startFrameLog();

  await loadFallbackFonts();

  EventBus.initialize();
  initAppLifecycleObserver();

  final result = await Future.wait<dynamic>([
    LoadBalancer.create(Platform.numberOfProcessors, IsolateRunner.spawn),
    initMixinDocumentsDirectory(),
  ]);
  loadBalancer = result.first as LoadBalancer?;
  // NSDataDetector loads its language data on its first use, which took about
  // 60 ms and delayed the first chat that the user opened.
  unawaited(
    prepareLinkRanges(const ['https://mixin.one']).catchError(
      (Object error) => e('warm link detection failed: $error'),
    ),
  );

  scheduleMicrotask(() async {
    initLogger(mixinLogDirectory.path);
    onWriteToFile = onWriteLogToFile;
    await dumpAppAndSystemInfoToLogger();
  });

  debugHighlightDeprecatedWidgets = true;

  unawaited(initListener());

  ansiColorDisabled = Platform.isIOS;

  if (Platform.isWindows || Platform.isMacOS) {
    await protocolHandler.register('mixin');
  }
  await parseAppInitialArguments(args);

  FlutterError.onError = (details) {
    e('FlutterError: ${details.exception} ${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    e('unhandled error: $error $stack');
    return true;
  };

  Hive.init(mixinDocumentsDirectory.path);
  await LocalStateStorage.init(mixinDocumentsDirectory.path);

  runApp(const ProviderScope(child: OverlaySupport.global(child: App())));

  if (!kPlatformIsDesktop) return;
  final window = await ensureMainWindow();
  if (window == null) {
    e('main window is null at startup');
    return;
  }

  if (Platform.isMacOS) {
    window
      ..titleBarStyle = TitleBarStyle.hidden
      ..isWindowControlButtonsVisible = true;
  }
  restoreWindowForStartup(window);

  if (Platform.isWindows) {
    const defaultWindowSize = Size(1280, 750);
    final workArea = workAreaUnderCursor;
    final Size screenSize;
    if (workArea != null) {
      i('workArea: $workArea');
      screenSize = workArea.size;
    } else {
      final screen = await getCurrentScreen();
      i('screen: ${screen?.visibleFrame} ${screen?.scaleFactor}');
      screenSize = screen == null
          ? defaultWindowSize
          : screen.visibleFrame.size / screen.scaleFactor;
    }
    final windowSize = Size(
      math.min(screenSize.width, defaultWindowSize.width),
      math.min(screenSize.height, defaultWindowSize.height),
    );
    window.setSize(windowSize.toNative(), false);
    if (workArea != null) {
      window.position = (workArea.center - windowSize.center(Offset.zero))
          .toNative();
    } else {
      window.center();
    }
  }

  window
    ..minimumSize = const Size(
      kSlidePageMinWidth + kResponsiveNavigationMinWidth,
      480,
    ).toNative()
    ..show()
    ..focus();
}
