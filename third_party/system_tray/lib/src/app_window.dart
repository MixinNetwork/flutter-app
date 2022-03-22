import 'dart:async';

import 'package:flutter/services.dart';

const String _kChannelName = "flutter/system_tray/app_window";

const String _kInitAppWindow = "InitAppWindow";
const String _kShowAppWindow = "ShowAppWindow";
const String _kHideAppWindow = "HideAppWindow";
const String _kCloseAppWindow = "CloseAppWindow";

/// Representation of native window
class AppWindow {
  AppWindow() {
    _platformChannel.setMethodCallHandler(_callbackHandler);
    _init();
  }

  static const MethodChannel _platformChannel = MethodChannel(_kChannelName);

  /// Show native window
  Future<void> show() async {
    await _platformChannel.invokeMethod(_kShowAppWindow);
  }

  /// Hide native window
  Future<void> hide() async {
    await _platformChannel.invokeMethod(_kHideAppWindow);
  }

  /// Close native window
  Future<void> close() async {
    await _platformChannel.invokeMethod(_kCloseAppWindow);
  }

  void _init() async {
    await _platformChannel.invokeMethod(_kInitAppWindow);
  }

  Future<void> _callbackHandler(MethodCall methodCall) async {}
}
