import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/ui/home/local_notification_center.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:isolate/isolate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:very_good_analysis/very_good_analysis.dart';
import 'package:window_size/window_size.dart';

import 'bloc/custom_bloc_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final currentScreen = await getCurrentScreen();
  if (currentScreen != null)
    setWindowFrame(Rect.fromCenter(
      center: currentScreen.visibleFrame.center,
      width: 1280,
      height: 750,
    ));
  setWindowMinSize(
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
