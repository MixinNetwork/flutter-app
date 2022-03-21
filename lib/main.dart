import 'dart:async';
import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:dart_vlc/dart_vlc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isolate/isolate.dart';
import 'package:path/path.dart' as p;
import 'package:protocol_handler/protocol_handler.dart';
import 'package:quick_breakpad/quick_breakpad.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

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
import 'utils/webview.dart';

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
  loadBalancer = result[0] as LoadBalancer?;

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
  DartVLC.initialize();

  await protocolHandler.register('mixin');

  HydratedBlocOverrides.runZoned(
    () => runZonedGuarded(
      () => runApp(const App()),
      (Object error, StackTrace stack) {
        if (!kLogMode) return;
        e('$error, $stack');
      },
      zoneSpecification: ZoneSpecification(
        handleUncaughtError: (_, __, ___, Object error, StackTrace stack) {
          if (!kLogMode) return;
          wtf('$error, $stack');
        },
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          if (!kLogMode) return;
          parent.print(zone, colorizeNonAnsi(line));
        },
      ),
    ),
    blocObserver: kDebugMode ? CustomBlocObserver() : null,
    storage: storage,
  );

  if (kPlatformIsDesktop) {
    doWhenWindowReady(() {
      appWindow.minSize =
          const Size(kSlidePageMinWidth + kResponsiveNavigationMinWidth, 480);
      // The macOS handle content size in native.
      if (!Platform.isMacOS) {
        appWindow.size = const Size(1280, 750);
        // FIXME remove this when the issues fixed.
        // https://github.com/bitsdojo/bitsdojo_window/issues/72
        // appWindow.alignment = Alignment.center;
      }
      appWindow.show();
    });
  }
}
