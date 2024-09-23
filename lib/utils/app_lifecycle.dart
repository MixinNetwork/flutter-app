import 'package:flutter/widgets.dart';

final _appObserver = _AppLifecycleObserver();

void initAppLifecycleObserver() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(_appObserver);
}

/// Check if app is on foreground.
bool get isAppActive => _appObserver._isActive.value;

ValueNotifier<bool> get appActiveListener => _appObserver._isActive;

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final _isActive = ValueNotifier<bool>(true);

  var _initialized = false;

  void initIfNeed() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isActive.value = state == AppLifecycleState.resumed;
  }
}
