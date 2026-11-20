import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../logger.dart';
import 'windows_device_id.dart';

// auto added by .github/workflows/manual-build.yml
const _kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '7.0.1',
);
const _kAppBuildNumber = String.fromEnvironment(
  'APP_BUILD_NUMBER',
  defaultValue: '0',
);

final _packageInfo = PackageInfo(
  appName: 'mixin',
  packageName: 'mixin_desktop',
  version: _kAppVersion,
  buildNumber: _kAppBuildNumber,
);

/// Returns the package info of the current app.
/// NOTE: Only available on main isolate.
Future<PackageInfo> getPackageInfo() async {
  if (Platform.isWindows) {
    return _packageInfo;
  }
  try {
    return await PackageInfo.fromPlatform();
  } catch (error, stack) {
    e('get package info failed. $error $stack');
  }
  // fallback if we can not get packageInfo dynamic.
  return _packageInfo;
}

Future<String?> generateUserAgent({
  Future<ProcessResult> Function(String, List<String>) runProcess = Process.run,
}) async {
  try {
    return await _generateUserAgent(await getPackageInfo(), runProcess);
  } catch (error, stack) {
    e('generate user agent failed. $error $stack');
    return null;
  }
}

Future<String> _generateUserAgent(
  PackageInfo packageInfo,
  Future<ProcessResult> Function(String, List<String>) runProcess,
) async {
  String? systemAndVersion;
  if (Platform.isMacOS) {
    try {
      final result = await runProcess('sw_vers', []);
      if (result.stdout != null) {
        final stdout = result.stdout as String;
        final map = Map.fromEntries(
          const LineSplitter()
              .convert(stdout)
              .map((e) => e.split(':'))
              .where((element) => element.length >= 2)
              .map((e) => MapEntry(e.first.trim(), e[1].trim())),
        );
        // example
        // ProductName: macOS
        // ProductVersion: 12.0.1
        // BuildVersion: 21A559
        systemAndVersion =
            '${map['ProductName']} ${map['ProductVersion']}(${map['BuildVersion']})';
      }
    } catch (e) {
      w('ws mac get user agent error: $e');
    }
  }
  systemAndVersion ??=
      '${Platform.operatingSystem}(${Platform.operatingSystemVersion})';
  return formatUserAgent(
    version: packageInfo.version,
    system: systemAndVersion,
    model: await readHardwareModel(runProcess: runProcess),
    locale: Platform.localeName,
  );
}

/// The model sits between the system and the locale, as in the iOS
/// User-Agent: `Mixin/1.2.3 (Flutter macOS 15.1(24B83); Mac16,10; en_US)`.
String formatUserAgent({
  required String version,
  required String system,
  required String? model,
  required String locale,
}) {
  final modelPart = model == null ? '' : '; $model';
  // A localized OS name such as "Windows 11 专业版" is not a valid header
  // value, and the server drops a request that carries one.
  return 'Mixin/$version (Flutter $system$modelPart; $locale)'.replaceAll(
    RegExp(r'[^\x20-\x7E]'),
    '',
  );
}

/// Reads the hardware model: `hw.model` on macOS (`Mac16,10`), the SMBIOS
/// manufacturer and product name on Windows and Linux (`Dell Inc. XPS 13
/// 9310`), or the device tree model on Linux boards without SMBIOS.
Future<String?> readHardwareModel({
  Future<ProcessResult> Function(String, List<String>) runProcess = Process.run,
  String linuxRoot = '/',
}) async {
  try {
    final String? model;
    if (Platform.isMacOS) {
      final result = await runProcess('/usr/sbin/sysctl', ['-n', 'hw.model']);
      model = result.exitCode == 0 ? result.stdout as String : null;
    } else if (Platform.isWindows) {
      model = readWindowsSmbiosSystemModel();
    } else if (Platform.isLinux) {
      model = readLinuxHardwareModel(root: linuxRoot);
    } else {
      model = null;
    }
    return cleanHardwareModel(model);
  } catch (error) {
    w('read hardware model failed: $error');
    return null;
  }
}

String? readLinuxHardwareModel({String root = '/'}) {
  String? read(String path) {
    final file = File(p.join(root, path));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  final dmi = [
    read('sys/class/dmi/id/sys_vendor'),
    read('sys/class/dmi/id/product_name'),
  ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);
  if (dmi.isNotEmpty) return dmi.join(' ');
  return read('proc/device-tree/model');
}

/// Keeps the model one User-Agent field: `;`, `(` and `)` would split it,
/// and the device tree model ends with a NUL.
String? cleanHardwareModel(String? model) {
  final cleaned = model
      ?.replaceAll(RegExp(r'[;()\x00-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}
