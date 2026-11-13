import 'dart:io';

import 'package:material_ui/material_ui.dart';

extension PlatformContextExtension on BuildContext {
  bool get textFieldAutoGainFocus =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
