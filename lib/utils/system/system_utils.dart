import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';

import '../logger.dart';
import '../platform.dart';
import 'windows.dart';

Future<void> setSystemUiWithAppBrightness(Brightness brightness) async {
  if (kPlatformIsMobile) {
    if (brightness == Brightness.light) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    }
    return;
  }
  if (Platform.isWindows) {
    final windowHandle = await getRawWindowHwnd();
    if (windowHandle == null) {
      e('failed to get window handle');
      return;
    }
    try {
      // https://stackoverflow.com/a/70693198/6258995
      // Update windows caption to dark mode when app brightness become dark.
      // Only available on Windows 10 and later.
      if (isWindows10OrGreater()) {
        final isDarkMode = malloc<BOOL>()
          ..value = brightness == Brightness.dark ? 1 : 0;
        DwmSetWindowAttribute(
          windowHandle,
          DWMWA_USE_IMMERSIVE_DARK_MODE,
          isDarkMode,
          sizeOf<BOOL>(),
        );
        malloc.free(isDarkMode);

        final captionColor = malloc<COLORREF>()
          ..value = brightness == Brightness.dark ? 0x2C3136 : 0xFFFFFF;
        DwmSetWindowAttribute(
          windowHandle,
          DWMWA_CAPTION_COLOR,
          captionColor,
          sizeOf<COLORREF>(),
        );
        malloc.free(captionColor);
      }
    } catch (error, stacktrace) {
      e('failed to set window attribute. $error $stacktrace');
    }
  }
}
