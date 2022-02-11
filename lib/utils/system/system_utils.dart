import 'dart:ffi';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';

import '../logger.dart';
import '../platform.dart';

/// Test for a minimum version of Windows.
///
/// Per:
/// https://docs.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getversionexw,
/// applications not manifested for Windows 8.1 or Windows 10 will return the
/// Windows 8 OS version value (6.2).
bool isWindowsVersionAtLeast(int majorVersion, int minorVersion) {
  final versionInfo = calloc<OSVERSIONINFO>();
  versionInfo.ref.dwOSVersionInfoSize = sizeOf<OSVERSIONINFO>();

  try {
    final result = GetVersionEx(versionInfo);

    if (result != 0) {
      if (versionInfo.ref.dwMajorVersion >= majorVersion) {
        if (versionInfo.ref.dwMinorVersion >= minorVersion) {
          return true;
        }
      }
      return false;
    } else {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(versionInfo);
  }
}

/// Test if running Windows is at least Windows 10.
bool isWindows10OrGreater() => isWindowsVersionAtLeast(10, 0);

void setSystemUiWithAppBrightness(Brightness brightness) {
  if (kPlatformIsMobile) {
    if (brightness == Brightness.light) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    }
    return;
  }
  if (Platform.isWindows) {
    final windowHandle = appWindow.handle;
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
            DWMWINDOWATTRIBUTE.DWMWA_USE_IMMERSIVE_DARK_MODE,
            isDarkMode,
            sizeOf<BOOL>());
        malloc.free(isDarkMode);

        final captionColor = malloc<COLORREF>()
          ..value = brightness == Brightness.dark ? 0x2C3136 : 0xFFFFFF;
        DwmSetWindowAttribute(
            windowHandle,
            DWMWINDOWATTRIBUTE.DWMWA_CAPTION_COLOR,
            captionColor,
            sizeOf<COLORREF>());
        malloc.free(captionColor);
      }
    } catch (error, stacktrace) {
      e('failed to set window attribute. $error $stacktrace');
    }
  }
}
