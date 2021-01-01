import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DesktopWindow.setWindowSize(const Size(1280, 750));
  // await DesktopWindow.setMinWindowSize(const Size(940, 640));
  runApp(App());
}
