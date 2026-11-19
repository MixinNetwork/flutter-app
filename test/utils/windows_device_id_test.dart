import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/utils/system/windows_device_id.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _rawSmbios(List<int> table) => Uint8List.fromList([
  0, 3, 4, 0, // Used20CallingMethod, major, minor, DmiRevision.
  ...(ByteData(
    4,
  )..setUint32(0, table.length, Endian.little)).buffer.asUint8List(),
  ...table,
]);

// A BIOS Information (type 0) structure with two strings.
const _biosInformation = [
  0, 0x18, 0x00, 0x00, //
  ...[1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ...[0x56, 0x65, 0x6e, 0x64, 0x6f, 0x72, 0], // "Vendor"
  ...[0x31, 0x2e, 0x30, 0], // "1.0"
  0,
];

// A System Information (type 1) structure with no strings.
List<int> _systemInformation(List<int> uuid) => [
  1, 0x1b, 0x01, 0x00, //
  1, 2, 3, 4, // Manufacturer, product name, version and serial strings.
  ...uuid,
  6, 0, 0, // Wake-up type, SKU and family strings.
  0, 0,
];

const _endOfTable = [127, 4, 0xff, 0xff, 0, 0];

void main() {
  test('formats the system UUID as WMI reports it', () {
    final raw = _rawSmbios([
      ..._biosInformation,
      ..._systemInformation(List.generate(16, (i) => i * 0x11)),
      ..._endOfTable,
    ]);

    expect(
      parseSmbiosSystemUuid(raw),
      '33221100-5544-7766-8899-AABBCCDDEEFF',
    );
  });

  test('returns null without a system information structure', () {
    expect(
      parseSmbiosSystemUuid(_rawSmbios([..._biosInformation, ..._endOfTable])),
      isNull,
    );
  });

  test('returns null for a truncated table', () {
    final raw = _rawSmbios([
      ..._biosInformation,
      ..._systemInformation(List.filled(16, 0xab)),
    ]);

    expect(parseSmbiosSystemUuid(raw.sublist(0, raw.length - 20)), isNull);
    expect(parseSmbiosSystemUuid(Uint8List(4)), isNull);
  });

  test(
    'reads the same UUID as WMI',
    () async {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '(Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID',
      ]);
      final wmiUuid = result.stdout.toString().trim();

      expect(wmiUuid, isNotEmpty);
      expect(readWindowsSmbiosSystemUuid(), wmiUuid);
    },
    skip: !Platform.isWindows,
  );
}
