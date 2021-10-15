import 'dart:io';

import 'package:flutter/material.dart';

extension PlatformContextExtension on BuildContext {
  bool get textFieldAutoGainFocus =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
