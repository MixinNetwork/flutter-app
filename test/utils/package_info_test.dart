import 'dart:io';
import 'dart:isolate';

import 'package:flutter_app/utils/system/package_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

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

  group('formatUserAgent', () {
    test('puts the model between the system and the locale', () {
      expect(
        formatUserAgent(
          version: '1.2.3',
          system: 'macOS 15.1(24B83)',
          model: 'Mac16,10',
          locale: 'en_US',
        ),
        'Mixin/1.2.3 (Flutter macOS 15.1(24B83); Mac16,10; en_US)',
      );
    });

    test('keeps the old format without a model', () {
      expect(
        formatUserAgent(
          version: '1.2.3',
          system: 'linux(6.8.0)',
          model: null,
          locale: 'en_US',
        ),
        'Mixin/1.2.3 (Flutter linux(6.8.0); en_US)',
      );
    });

    test('drops characters that are not valid in a header', () {
      expect(
        formatUserAgent(
          version: '1.2.3',
          system: 'Windows 11 专业版',
          model: 'LENOVO 20XW',
          locale: 'zh_CN',
        ),
        'Mixin/1.2.3 (Flutter Windows 11 ; LENOVO 20XW; zh_CN)',
      );
    });
  });

  group('cleanHardwareModel', () {
    test('keeps the model one field', () {
      expect(
        cleanHardwareModel(' ACME (R); Box\t 9\n'),
        'ACME R Box 9',
      );
    });

    test('removes the NUL at the end of a device tree model', () {
      expect(
        cleanHardwareModel('Raspberry Pi 4 Model B Rev 1.4\u0000'),
        'Raspberry Pi 4 Model B Rev 1.4',
      );
    });

    test('returns null for a blank model', () {
      expect(cleanHardwareModel(' \n\u0000'), isNull);
      expect(cleanHardwareModel(null), isNull);
    });
  });

  group('readLinuxHardwareModel', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('hardware_model'));
    tearDown(() => root.deleteSync(recursive: true));

    void write(String path, String content) => (File(
      p.join(root.path, path),
    )..createSync(recursive: true)).writeAsStringSync(content);

    test('joins the DMI vendor and product name', () {
      write('sys/class/dmi/id/sys_vendor', 'Dell Inc.\n');
      write('sys/class/dmi/id/product_name', 'XPS 13 9310\n');
      write('proc/device-tree/model', 'unused\u0000');

      expect(readLinuxHardwareModel(root: root.path), 'Dell Inc. XPS 13 9310');
    });

    test('uses the DMI product name alone', () {
      write('sys/class/dmi/id/sys_vendor', '\n');
      write('sys/class/dmi/id/product_name', 'Virtual Machine\n');

      expect(readLinuxHardwareModel(root: root.path), 'Virtual Machine');
    });

    test('falls back to the device tree model', () {
      write('proc/device-tree/model', 'Raspberry Pi 4 Model B Rev 1.4\u0000');

      expect(
        cleanHardwareModel(readLinuxHardwareModel(root: root.path)),
        'Raspberry Pi 4 Model B Rev 1.4',
      );
    });

    test('returns null without DMI or a device tree', () {
      expect(readLinuxHardwareModel(root: root.path), isNull);
    });
  });

  final macModelLookups = <String, (ProcessResult Function(), String)>{
    'successful lookup': (
      () => ProcessResult(0, 0, ' Macmini9,1\n', ''),
      'Macmini9,1; ',
    ),
    'blank output': (() => ProcessResult(0, 0, ' \t\n', ''), ''),
    'nonzero exit': (() => ProcessResult(0, 1, 'Macmini9,1', ''), ''),
    'process error': (
      () =>
          throw const ProcessException('/usr/sbin/sysctl', ['-n', 'hw.model']),
      '',
    ),
  };

  for (final MapEntry(key: description, value: (lookup, model))
      in macModelLookups.entries) {
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
        'Mixin/1.2.3 (Flutter macOS 12.0.1(21A559); $model${Platform.localeName})',
      );
    }, skip: !Platform.isMacOS);
  }

  test('includes the model of this host, from a worker isolate', () async {
    final (userAgent, model) = await Isolate.run(() async {
      PackageInfo.setMockInitialValues(
        appName: 'Mixin',
        packageName: 'mixin',
        version: '1.2.3',
        buildNumber: '42',
        buildSignature: '',
      );
      return (await generateUserAgent(), await readHardwareModel());
    });
    // Shown in the CI log of each platform.
    // ignore: avoid_print
    print('User-Agent on this host: $userAgent');

    expect(userAgent, matches(r'^Mixin/[^ ]+ \(Flutter .+\)$'));
    if (model != null) expect(userAgent, contains('; $model; '));
    // The CI runners are virtual machines that report a model.
    if (Platform.environment['CI'] == 'true') expect(model, isNotNull);
  });
}
