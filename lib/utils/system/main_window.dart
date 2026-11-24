import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:nativeapi/nativeapi.dart' show DisplayManager;
import 'package:window_manager/window_manager.dart';

import '../platform.dart';
import 'windows.dart';

Window? _mainWindow;

Window? get mainWindow {
  if (!kPlatformIsDesktop) return null;
  // Resolve at startup, before a bot window can take focus.
  return _mainWindow ??= WindowManager.instance.getCurrent();
}

/// Resolves the app's primary window, falling back to the hidden runner HWND
/// on Windows where `WindowManager.getCurrent()` only returns active windows.
Future<Window?> ensureMainWindow() async {
  final existing = mainWindow;
  if (existing != null) return existing;
  if (!Platform.isWindows) return null;
  final hwnd = await getRawWindowHwnd();
  if (hwnd == null || hwnd == 0) return null;
  return _mainWindow = Window.createWithNativeWindow(
    Pointer<Void>.fromAddress(hwnd),
  );
}

void restoreWindowForStartup(Window window) {
  if (window.isFullScreen) window.isFullScreen = false;
  if (window.isMaximized) window.unmaximize();
  if (window.isMinimized) window.restore();
}

void showMainWindow() {
  final window = mainWindow;
  if (window == null) return;
  if (window.isMinimized) window.restore();
  window.show();
}

Rect? get workAreaUnderCursor {
  const manager = DisplayManager.instance;
  final cursor = manager.getCursorPosition().toOffset();
  for (final display in manager.getAll()) {
    final bounds = display.position.toOffset() & display.size.toSize();
    if (bounds.contains(cursor)) return display.workArea.toRect();
  }
  return manager.getPrimary()?.workArea.toRect();
}
