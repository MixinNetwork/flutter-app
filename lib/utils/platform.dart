import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

bool kPlatformIsDarwin = Platform.isMacOS || Platform.isIOS;

bool kPlatformIsDesktop =
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;

bool kPlatformIsMobile = Platform.isAndroid || Platform.isIOS;

Future<String> getPlatformVersion() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isMacOS) {
    final macOsInfo = await deviceInfo.macOsInfo;
    return macOsInfo.osRelease;
  }
  if (Platform.isLinux) {
    final linuxInfo = await deviceInfo.linuxInfo;
    return linuxInfo.prettyName;
  }
  if (Platform.isWindows) {
    final windowsInfo = await deviceInfo.windowsInfo;
    return windowsInfo.computerName;
  }
  return '';
}
