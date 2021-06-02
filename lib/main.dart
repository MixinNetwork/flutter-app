import 'dart:ui';

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
  runApp(App());

  doWhenWindowReady(() {
    appWindow.minSize =
        const Size(kSlidePageMinWidth + kResponsiveNavigationMinWidth, 480);
    appWindow.size = const Size(1280, 750);
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}
