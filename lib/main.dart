import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/local_notification_center.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:isolate/load_balancer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import 'bloc/custom_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DesktopWindow.setWindowSize(const Size(1280, 750));
  await DesktopWindow.setMinWindowSize(
      const Size(slidePageMinWidth + responsiveNavigationMinWidth, 480));

  LoadBalancerUtils.loadBalancer =
      await LoadBalancer.create(16, IsolateRunner.spawn);
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  debugHighlightDeprecatedWidgets = true;

  if (kDebugMode) Bloc.observer = CustomBlocObserver();
  unawaited(LocalNotificationCenter.initListener());
  runApp(App());
}
