import 'dart:io';
import 'dart:isolate';

import 'package:flutter_app/utils/system/package_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<String> _readCommand(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  expect(result.exitCode, 0);
  return (result.stdout as String).trim();
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Mixin',
      packageName: 'mixin',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  final modelLookups = <String, (ProcessResult Function(), String)>{
    'successful lookup': (
      () => ProcessResult(0, 0, ' Macmini9,1\n', ''),
      '; model=Macmini9,1',
    ),
    'blank output': (() => ProcessResult(0, 0, ' \t\n', ''), ''),
    'nonzero exit': (() => ProcessResult(0, 1, 'Macmini9,1', ''), ''),
    'process error': (
      () =>
          throw const ProcessException('/usr/sbin/sysctl', ['-n', 'hw.model']),
      '',
    ),
  };

  for (final MapEntry(key: description, value: (lookup, suffix))
      in modelLookups.entries) {
    test('formats the macOS UA after $description', () async {
      final userAgent = await generateUserAgent(
        runProcess: (executable, arguments) async {
          if (executable == 'sw_vers') {
            return ProcessResult(
              0,
              0,
              'ProductName: macOS測試\nProductVersion: 12.0.1\nBuildVersion: 21A559\n',
              '',
            );
          }
          expect(executable, '/usr/sbin/sysctl');
          expect(arguments, ['-n', 'hw.model']);
          return lookup();
        },
      );

      expect(
        userAgent,
        'Mixin/1.2.3 (Flutter macOS 12.0.1(21A559); ${Platform.localeName}$suffix)',
      );
    }, skip: !Platform.isMacOS);
  }

  test('keeps the UA format on other platforms', () async {
    final commands = <String>[];
    final userAgent = await generateUserAgent(
      runProcess: (executable, _) async {
        commands.add(executable);
        return ProcessResult(0, 1, '', '');
      },
    );

    expect(commands, isEmpty);
    final packageInfo = await getPackageInfo();
    expect(
      userAgent,
      'Mixin/${packageInfo.version} (Flutter '
              '${Platform.operatingSystem}(${Platform.operatingSystemVersion}); '
              '${Platform.localeName})'
          .replaceAll(RegExp(r'[^\x20-\x7E]'), ''),
    );
  }, skip: Platform.isMacOS);

  test('includes the host macOS model from a worker isolate', () async {
    final product = await _readCommand('/usr/bin/sw_vers', ['-productName']);
    final version = await _readCommand('/usr/bin/sw_vers', ['-productVersion']);
    final build = await _readCommand('/usr/bin/sw_vers', ['-buildVersion']);
    final model = await _readCommand('/usr/sbin/sysctl', ['-n', 'hw.model']);
    expect(model, isNotEmpty);

    final (userAgent, locale) = await Isolate.run(
      () async => (await generateUserAgent(), Platform.localeName),
    );

    final platformDetails = RegExp.escape(
      '(Flutter $product $version($build); $locale; model=$model)',
    );
    expect(userAgent, matches('^Mixin/[^ ]+ $platformDetails\$'));
  }, skip: !Platform.isMacOS);
}
