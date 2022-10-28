import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ansicolor/ansicolor.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isolate/isolate.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path/path.dart' as p;
import 'package:protocol_handler/protocol_handler.dart';
import 'package:quick_breakpad/quick_breakpad.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'app.dart';
import 'bloc/custom_bloc_observer.dart';
import 'ui/home/home.dart';
import 'utils/app_lifecycle.dart';
import 'utils/file.dart';
import 'utils/load_balancer_utils.dart';
import 'utils/local_notification_center.dart';
import 'utils/logger.dart';
import 'utils/platform.dart';
import 'utils/system/system_fonts.dart';
import 'utils/web_view/web_view_desktop.dart';

Future<void> main(List<String> args) async {
  EquatableConfig.stringify = true;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  WidgetsFlutterBinding.ensureInitialized();

  await loadFallbackFonts();

  // show custom web view navigation bar.
  if (runWebViewNavigationBar(args)) {
    return;
  }

  initAppLifecycleObserver();

  final result = await Future.wait<dynamic>([
    LoadBalancer.create(Platform.numberOfProcessors, IsolateRunner.spawn),
    initMixinDocumentsDirectory(),
  ]);
  loadBalancer = result.first as LoadBalancer?;

  // init crash report dump path.
  // default to executable directory, but we might haven't write permission to
  // executable directory, so use documents directory instead.
  unawaited(QuickBreakpad.setDumpPath(p.join(
    mixinDocumentsDirectory.path,
    'crash',
  )));

  unawaited(LogFileManager.init(mixinLogDirectory.path));

  final storage = await HydratedStorage.build(
    storageDirectory: mixinDocumentsDirectory,
  );

  debugHighlightDeprecatedWidgets = true;

  unawaited(initListener());

  ansiColorDisabled = Platform.isIOS;

  if (Platform.isWindows || Platform.isMacOS) {
    await protocolHandler.register('mixin');
  }

  FlutterError.onError = (details) {
    e('FlutterError: ${details.exception} ${details.stack}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    e('unhandled error: $error $stack');
    return true;
  };

  HydratedBlocOverrides.runZoned(
    () => runApp(const OverlaySupport.global(child: App())),
    blocObserver: kDebugMode ? CustomBlocObserver() : null,
    storage: storage,
  );

  if (kPlatformIsDesktop) {
    Size? windowSize;
    if (!Platform.isMacOS) {
      final screen = await getCurrentScreen();
      i('screen: ${screen?.visibleFrame} ${screen?.scaleFactor}');
      const defaultWindowSize = Size(1280, 750);
      if (screen != null) {
        var screenSize = screen.visibleFrame.size;
        if (Platform.isWindows) {
          screenSize = screenSize / screen.scaleFactor;
        }
        final size = Size(
          math.min(screenSize.width, defaultWindowSize.width),
          math.min(screenSize.height, defaultWindowSize.height),
        );
        windowSize = size;
      } else {
        windowSize = defaultWindowSize;
      }
    }

    final windowOptions = WindowOptions(
      titleBarStyle: Platform.isMacOS ? TitleBarStyle.hidden : null,
      minimumSize:
          const Size(kSlidePageMinWidth + kResponsiveNavigationMinWidth, 480),
      size: windowSize,
      center: Platform.isMacOS ? null : true,
    );

    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
