import 'dart:async';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/home/home.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:isolate/load_balancer.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DesktopWindow.setWindowSize(const Size(1280, 750));
  await DesktopWindow.setMinWindowSize(
      const Size(slidePageMinWidth + responsiveNavigationMinWidth, 480));

  final list = await Future.wait([
    LoadBalancer.create(16, IsolateRunner.spawn),
    HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    ),
  ]);

  LoadBalancerUtils.loadBalancer = list[0];
  HydratedBloc.storage = list[1];

  debugHighlightDeprecatedWidgets = true;
  runApp(App());
}
