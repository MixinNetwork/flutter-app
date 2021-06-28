import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:ansicolor/ansicolor.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isolate/isolate.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import 'app.dart';
import 'bloc/custom_bloc_observer.dart';
import 'ui/home/home.dart';
import 'ui/home/local_notification_center.dart';
import 'utils/file.dart';
import 'utils/load_balancer_utils.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(LoadBalancer.create(64, IsolateRunner.spawn).then((value) {
    loadBalancer = value;
  }));

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getMixinDocumentsDirectory(),
  );

  debugHighlightDeprecatedWidgets = true;

  if (kDebugMode) Bloc.observer = CustomBlocObserver();
  unawaited(initListener());

  ansiColorDisabled = false;
  runZonedGuarded(
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
  );

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
