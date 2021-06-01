import 'dart:async';
import 'dart:ui';

import 'package:ansicolor/ansicolor.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:isolate/isolate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import 'app.dart';
import 'bloc/custom_bloc_observer.dart';
import 'ui/home/home.dart';
import 'ui/home/local_notification_center.dart';
import 'utils/load_balancer_utils.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(LoadBalancer.create(64, IsolateRunner.spawn).then((value) {
    loadBalancer = value;
  }));

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  debugHighlightDeprecatedWidgets = true;

  if (kDebugMode) Bloc.observer = CustomBlocObserver();
  unawaited(initListener());

  ansiColorDisabled = false;
  runZonedGuarded(() => runApp(App()), (Object error, StackTrace stack) {
    e('$error, $stack');
  }, zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
    parent.print(zone, colorize(line));
  }));

  doWhenWindowReady(() {
    appWindow.minSize =
        const Size(kSlidePageMinWidth + kResponsiveNavigationMinWidth, 480);
    appWindow.size = const Size(1280, 750);
    // FIXME remove this when the issues fixed.
    // https://github.com/bitsdojo/bitsdojo_window/issues/72
    // appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}
