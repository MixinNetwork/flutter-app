import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:ui_device/ui_device.dart' as ui_device;

import '../crypto/uuid/uuid.dart';
import 'logger.dart';

bool kPlatformIsDarwin = Platform.isMacOS || Platform.isIOS;

bool kPlatformIsDesktop =
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;

bool kPlatformIsMobile = Platform.isAndroid || Platform.isIOS;

bool kPlatformIsPad = Platform.isIOS && !kPlatformIsIphone;

bool kPlatformIsIphone = Platform.isIOS &&
    ui_device.current.userInterfaceIdiom ==
        ui_device.UIUserInterfaceIdiom.UIUserInterfaceIdiomPhone;

Future<String> getPlatformVersion() async {
  try {
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
  } catch (error, stack) {
    e('failed to get platform version. $error $stack');
  }
  return '${defaultTargetPlatform.name}_unknown';
}

Future<String> getDeviceId() async {
  try {
    final id = (await PlatformDeviceId.getDeviceId)?.trim();
    if (id == null || id.isEmpty) {
      throw Exception("${Platform.operatingSystem}'s device id is empty");
    }
    if (Platform.isAndroid || kIsWeb) {
      return nameUuidFromBytes(utf8.encode(id)).uuid;
    }

    return id;
  } catch (error, stack) {
    e('failed to get device id. $error $stack');
  }
  return 'unknown';
}
