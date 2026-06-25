import 'package:flutter/foundation.dart';

import 'desktop_shell_layout.dart';

class LeftRailController extends ValueNotifier<bool> {
  LeftRailController(DesktopShellLayout layout) : super(layout.hasDrawer);

  void sync(DesktopShellLayout layout) => value = layout.hasDrawer;
}
