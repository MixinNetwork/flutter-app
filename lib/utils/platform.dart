import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:ui_device/ui_device.dart' as ui_device;
import 'package:uuid/uuid.dart';

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
    final String? id;
    if (Platform.isWindows) {
      id = (await _getWindowsDeviceId())?.trim();
    } else if (Platform.isMacOS) {
      id = (await _getMacOSDeviceId())?.trim();
    } else if (Platform.isLinux) {
      id = (await _getLinuxDeviceId())?.trim();
    } else {
      id = (await PlatformDeviceId.getDeviceId)?.trim();
    }
    if (id == null || id.isEmpty) {
      throw Exception("${Platform.operatingSystem}'s device id is empty");
    }
    if (Platform.isAndroid || kIsWeb || Platform.isLinux) {
      return nameUuidFromBytes(utf8.encode(id)).uuid;
    }

    return id;
  } catch (error, stack) {
    e('failed to get device id. $error $stack');
  }
  return 'unknown';
}

// https://man7.org/linux/man-pages/man5/machine-id.5.html
Future<String?> _getLinuxDeviceId() async {
  final process = await Process.run(
    'cat',
    ['/etc/machine-id'],
  );

  if (process.stdout == null) {
    e('failed to get linux device id. ${process.stderr}');
    return null;
  }

  final machineId = process.stdout.toString().trim();

  // Check machineId is valid.
  // the machineId should be hexademical 32-characters, lowercase.
  if (machineId.length != 32) {
    e('failed to get linux device id. machineId length is not 32. $machineId');
    return null;
  }
  return machineId;
}

// ref: https://github.com/BestBurning/platform_device_id/issues/15#issuecomment-1064081170
Future<String?> _getWindowsDeviceId() async {
  final process = await Process.start(
    'wmic',
    ['csproduct', 'get', 'UUID'],
    mode: ProcessStartMode.detachedWithStdio,
  );
  final result = await process.stdout.transform(utf8.decoder).toList();
  String? deviceID;
  for (final element in result) {
    final item = element.replaceAll(RegExp('\r|\n|\\s|UUID|uuid'), '');
    if (item.isNotEmpty) {
      deviceID = item;
    }
  }
  return deviceID;
}

// ref: https://github.com/BestBurning/platform_device_id/blob/master/platform_device_id_macos/macos/Classes/PlatformDeviceIdMacosPlugin.swift
// since platform_device_id_macos would block UI thread,
// so replace with dart implementation.
Future<String?> _getMacOSDeviceId() async {
  final process = await Process.run(
    'ioreg',
    ['-rd1', '-c', 'IOPlatformExpertDevice'],
  );
  if (process.stdout == null) {
    return null;
  }
  final result = process.stdout.toString();

  //    "IOPlatformUUID" = "U-U-I-D"
  final matches =
      RegExp(r'(?<=IOPlatformUUID"\s=\s").*(?=")').firstMatch(result);
  if (matches == null) {
    e('failed to get macos device id. $result');
    return null;
  }
  final uuid = matches[0]?.toLowerCase();
  if (uuid == null) {
    e('get macos device id: failed to get group. $matches');
    return null;
  }
  if (!Uuid.isValidUUID(fromString: uuid)) {
    e('get macos device id: invalid uuid. $uuid');
  }
  return uuid;
}
