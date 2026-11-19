import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:ui_device/ui_device.dart' as ui_device;
import 'package:uuid/uuid.dart';

import '../crypto/uuid/uuid.dart';
import 'file.dart';
import 'logger.dart';
import 'system/windows_device_id.dart';

bool kPlatformIsDarwin = Platform.isMacOS || Platform.isIOS;

bool kPlatformIsDesktop =
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;

bool kPlatformIsMobile = Platform.isAndroid || Platform.isIOS;

bool kPlatformIsPad = Platform.isIOS && !kPlatformIsIphone;

bool kPlatformIsIphone =
    Platform.isIOS &&
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

String? _cachedDeviceId;

Future<String> getDeviceId() async {
  final cached = _cachedDeviceId;
  if (cached != null) return cached;
  try {
    String? id;
    if (Platform.isWindows) {
      id = (await _getWindowsDeviceId())?.trim();
    } else if (Platform.isMacOS) {
      id = (await _getMacOSDeviceId())?.trim();
    } else if (Platform.isLinux) {
      id = (await _getLinuxDeviceId())?.trim();
    } else if (Platform.isAndroid) {
      final androidId = await const AndroidId().getId();
      id = androidId?.trim();
    } else if (Platform.isIOS) {
      final deviceInfo = await DeviceInfoPlugin().iosInfo;
      id = deviceInfo.identifierForVendor?.trim();
    }
    if (id == null || id.isEmpty) {
      throw Exception("${Platform.operatingSystem}'s device id is empty");
    }
    if (Platform.isAndroid || kIsWeb || Platform.isLinux) {
      return _cachedDeviceId = nameUuidFromBytes(utf8.encode(id)).uuid;
    }

    return _cachedDeviceId = id.toLowerCase();
  } catch (error, stack) {
    e('failed to get device id. $error $stack');
  }
  return 'unknown';
}

// https://man7.org/linux/man-pages/man5/machine-id.5.html
Future<String?> _getLinuxDeviceId() async {
  final process = await Process.run('cat', ['/etc/machine-id']);

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

/// Returns the SMBIOS system UUID that earlier versions read with WMIC, so
/// the id, and the account bound to it, survives an upgrade.
Future<String?> _getWindowsDeviceId() async {
  final fallbackFile = File(
    p.join(mixinDocumentsDirectory.path, 'device_id'),
  );
  // A machine that needed the fallback id once keeps using it.
  if (fallbackFile.existsSync()) {
    final id = fallbackFile.readAsStringSync().trim();
    if (id.isNotEmpty) return id;
  }

  final sources = <(String, FutureOr<String?> Function())>[
    ('SMBIOS', readWindowsSmbiosSystemUuid),
    (
      'wmic',
      () => _runWindowsUuidCommand('wmic', ['csproduct', 'get', 'UUID']),
    ),
    (
      'powershell',
      () => _runWindowsUuidCommand('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '(Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID',
      ]),
    ),
  ];
  for (final (name, read) in sources) {
    try {
      final id = (await read())?.trim();
      if (id != null && id.isNotEmpty) return id;
      w('windows device id from $name is empty');
    } catch (error, stack) {
      w('failed to get windows device id from $name. $error $stack');
    }
  }

  final id = const Uuid().v4();
  await fallbackFile.parent.create(recursive: true);
  await fallbackFile.writeAsString(id);
  w('windows device id falls back to a generated id');
  return id;
}

Future<String?> _runWindowsUuidCommand(
  String executable,
  List<String> arguments,
) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stderr}',
      result.exitCode,
    );
  }
  final id = result.stdout.toString().replaceAll(
    RegExp(r'\s|UUID', caseSensitive: false),
    '',
  );
  return id.isEmpty ? null : id;
}

// ref: https://github.com/BestBurning/platform_device_id/blob/master/platform_device_id_macos/macos/Classes/PlatformDeviceIdMacosPlugin.swift
// since platform_device_id_macos would block UI thread,
// so replace with dart implementation.
Future<String?> _getMacOSDeviceId() async {
  final process = await Process.run('ioreg', [
    '-rd1',
    '-c',
    'IOPlatformExpertDevice',
  ]);
  if (process.stdout == null) {
    return null;
  }
  final result = process.stdout.toString();

  //    "IOPlatformUUID" = "U-U-I-D"
  final matches = RegExp(
    r'(?<=IOPlatformUUID"\s=\s").*(?=")',
  ).firstMatch(result);
  if (matches == null) {
    e('failed to get macos device id. $result');
    return null;
  }
  final uuid = matches[0];
  if (uuid == null) {
    e('get macos device id: failed to get group. $matches');
    return null;
  }
  if (!Uuid.isValidUUID(fromString: uuid)) {
    e('get macos device id: invalid uuid. $uuid');
  }
  return uuid;
}
