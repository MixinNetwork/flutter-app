import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ansicolor/ansicolor.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isolate/isolate.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:rhttp/rhttp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';

import 'app.dart';
import 'bloc/custom_bloc_observer.dart';
import 'constants/env.dart';
import 'ui/home/home.dart';
import 'ui/setting/log_page.dart';
import 'utils/app_lifecycle.dart';
import 'utils/event_bus.dart';
import 'utils/file.dart';
import 'utils/load_balancer_utils.dart';
import 'utils/local_notification_center.dart';
import 'utils/logger.dart';
import 'utils/platform.dart';
import 'utils/system/system_fonts.dart';
import 'utils/web_view/web_view_desktop.dart';
import 'widgets/protocol_handler.dart';

Future<void> main(List<String> args) async {
  await _runApp(args);
}

Future<void> _runApp(List<String> args) async {
  EquatableConfig.stringify = true;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  await Rhttp.init();

  WidgetsFlutterBinding.ensureInitialized();

  await loadFallbackFonts();

  // show custom web view navigation bar.
  if (runWebViewNavigationBar(args)) {
    return;
  }

  EventBus.initialize();
  initAppLifecycleObserver();

  final result = await Future.wait<dynamic>([
    LoadBalancer.create(Platform.numberOfProcessors, IsolateRunner.spawn),
    initMixinDocumentsDirectory(),
  ]);
  loadBalancer = result.first as LoadBalancer?;

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

  if (Env.sentryDsn.isNotEmpty) {
    i('app running with sentry');
  } else {
    e('app running without sentry');
  }

  Hive.init(mixinDocumentsDirectory.path);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(mixinDocumentsDirectory.path),
  );
  if (kDebugMode) {
    Bloc.observer = CustomBlocObserver();
  }

  runApp(const ProviderScope(child: OverlaySupport.global(child: App())));

  if (kPlatformIsDesktop) {
    Size? windowSize;
    if (Platform.isWindows) {
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
      minimumSize: const Size(
        kSlidePageMinWidth + kResponsiveNavigationMinWidth,
        480,
      ),
      size: windowSize,
      center: Platform.isWindows ? true : null,
    );

    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
