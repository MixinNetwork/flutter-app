import 'dart:io';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

final _appObserver = _AppLifecycleObserver();

final _desktopPlatform =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

void initAppLifecycleObserver() {
  if (!_desktopPlatform) {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance!.addObserver(_appObserver);
  }
}

/// Check if app is on foreground.
bool get isAppActive {
  if (_desktopPlatform) {
    return DesktopLifecycle.instance.isActive.value;
  }
  return _appObserver._isActive.value;
}

ValueListenable<bool> get appActiveListener {
  if (_desktopPlatform) {
    return DesktopLifecycle.instance.isActive;
  }
  return _appObserver._isActive;
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final _isActive = ValueNotifier<bool>(true);

  var _initialized = false;

  void initIfNeed() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    assert(WidgetsBinding.instance != null);
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isActive.value = state == AppLifecycleState.resumed;
  }
}
