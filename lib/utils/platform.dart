import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../crypto/uuid/uuid.dart';
import 'logger.dart';

bool kPlatformIsDarwin = Platform.isMacOS || Platform.isIOS;

bool kPlatformIsDesktop =
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;

bool kPlatformIsMobile = Platform.isAndroid || Platform.isIOS;

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
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final id = iosInfo.identifierForVendor;
      if (id != null) {
        return id;
      }
      e('failed to get iOS device id');
    }
    if (Platform.isAndroid) {
      final id = await const AndroidId().getId();
      if (id != null) {
        return nameUuidFromBytes(utf8.encode(id)).uuid;
      }
      e('failed to get Android device id');
    }
    if (Platform.isMacOS) {
      final macOsInfo = await deviceInfo.macOsInfo;
      final id = macOsInfo.systemGUID;
      if (id != null) {
        return nameUuidFromBytes(utf8.encode(id)).uuid;
      }
      e('failed to get MacOS device id');
    }
    if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      final id = linuxInfo.machineId;
      if (id != null) {
        return nameUuidFromBytes(utf8.encode(id)).uuid;
      }
      e('failed to get Linux device id');
    }
    if (Platform.isWindows) {
      assert(false, 'Windows is not supported');
    }
  } catch (error, stack) {
    e('failed to get device id. $error $stack');
  }
  return 'unknown';
}
