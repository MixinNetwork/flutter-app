import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';

const _methodChannel = MethodChannel('mixin_desktop/raw_hwnd');

Future<int?> getRawWindowHwnd() =>
    _methodChannel.invokeMethod<int>('getRawWindowHandle');

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
