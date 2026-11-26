// Run with: flutter test integration_test/package_info_test.dart -d <windows|macos|linux>
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_app/utils/system/package_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reads real PackageInfo and User-Agent on main and worker isolates', (
    tester,
  ) async {
    final mainInfo = await getPackageInfo();
    final mainUserAgent = await generateUserAgent();

    // ignore: avoid_print
    print(
      'Main isolate PackageInfo: appName=${mainInfo.appName}, '
      'packageName=${mainInfo.packageName}, '
      'version=${mainInfo.version}, buildNumber=${mainInfo.buildNumber}',
    );
    // ignore: avoid_print
    print('Main isolate User-Agent: $mainUserAgent');

    expect(mainInfo.version, matches(r'^\d+\.\d+\.\d+$'));
    expect(mainInfo.version, isNot('0.0.0'));
    expect(mainInfo.version, isNot('1.0.0'));
    expect(mainInfo.buildNumber, matches(r'^\d+$'));
    expect(int.parse(mainInfo.buildNumber), greaterThan(0));
    expect(mainUserAgent, startsWith('Mixin/${mainInfo.version} (Flutter '));

    final rootToken = ui.RootIsolateToken.instance!;
    final workerResult = await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
      ui.DartPluginRegistrant.ensureInitialized();
      final info = await getPackageInfo();
      final userAgent = await generateUserAgent();
      return (
        appName: info.appName,
        packageName: info.packageName,
        version: info.version,
        buildNumber: info.buildNumber,
        userAgent: userAgent,
      );
    });

    // ignore: avoid_print
    print(
      'Worker isolate PackageInfo: appName=${workerResult.appName}, '
      'packageName=${workerResult.packageName}, '
      'version=${workerResult.version}, buildNumber=${workerResult.buildNumber}',
    );
    // ignore: avoid_print
    print('Worker isolate User-Agent: ${workerResult.userAgent}');

    expect(workerResult.version, mainInfo.version);
    expect(workerResult.buildNumber, mainInfo.buildNumber);
    expect(workerResult.appName, mainInfo.appName);
    expect(workerResult.packageName, mainInfo.packageName);
    // Platform.localeName is 'und' inside a spawned isolate, so check the
    // version/system/model prefix rather than exact equality with mainUserAgent.
    expect(
      workerResult.userAgent,
      startsWith('Mixin/${mainInfo.version} (Flutter '),
    );
  });
}
