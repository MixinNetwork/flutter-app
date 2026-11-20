import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../logger.dart';

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
  var modelSuffix = '';
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
    try {
      final result = await runProcess('/usr/sbin/sysctl', ['-n', 'hw.model']);
      final model = (result.stdout as String).trim();
      if (result.exitCode == 0 && model.isNotEmpty) {
        modelSuffix = '; model=$model';
      }
    } catch (e) {
      w('ws mac get hardware model error: $e');
    }
  }
  systemAndVersion ??=
      '${Platform.operatingSystem}(${Platform.operatingSystemVersion})';
  // A localized OS name such as "Windows 11 专业版" is not a valid header
  // value, and the server drops a request that carries one.
  return 'Mixin/${packageInfo.version} (Flutter $systemAndVersion; ${Platform.localeName}$modelSuffix)'
      .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
}
