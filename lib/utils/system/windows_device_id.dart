import 'dart:ffi';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// 'RSMB', the raw SMBIOS firmware table provider.
const _rsmbProvider = 0x52534D42;

/// Reads the SMBIOS system UUID, the value that
/// `wmic csproduct get UUID` and `Win32_ComputerSystemProduct.UUID` report.
///
/// WMIC is removed from recent Windows releases, so this reads the firmware
/// table directly instead of starting a process.
String? readWindowsSmbiosSystemUuid() {
  final raw = _readRawSmbios();
  return raw == null ? null : parseSmbiosSystemUuid(raw);
}

/// Reads the manufacturer and product name of the SMBIOS system information,
/// such as "Dell Inc. XPS 13 9310".
String? readWindowsSmbiosSystemModel() {
  final raw = _readRawSmbios();
  return raw == null ? null : parseSmbiosSystemModel(raw);
}

Uint8List? _readRawSmbios() {
  final getSystemFirmwareTable = DynamicLibrary.open('kernel32.dll')
      .lookupFunction<
        Uint32 Function(Uint32, Uint32, Pointer<Uint8>, Uint32),
        int Function(int, int, Pointer<Uint8>, int)
      >(
        'GetSystemFirmwareTable',
      );
  final size = getSystemFirmwareTable(_rsmbProvider, 0, nullptr, 0);
  if (size == 0) return null;

  final buffer = calloc<Uint8>(size);
  try {
    final written = getSystemFirmwareTable(_rsmbProvider, 0, buffer, size);
    if (written == 0 || written > size) return null;
    return Uint8List.fromList(buffer.asTypedList(written));
  } finally {
    calloc.free(buffer);
  }
}

/// Parses the UUID of the System Information (type 1) structure from the
/// `RawSMBIOSData` returned by `GetSystemFirmwareTable('RSMB')`.
///
/// The first three fields are little-endian, as Windows has always formatted
/// them, so the result matches what WMI reports.
String? parseSmbiosSystemUuid(Uint8List raw) {
  final system = _findSystemInformation(raw);
  // The UUID occupies offsets 08h to 17h.
  if (system == null || system.length < 0x18) return null;
  return _formatSmbiosUuid(
    raw.sublist(system.offset + 8, system.offset + 0x18),
  );
}

/// Parses the manufacturer (offset 04h) and product name (offset 05h) strings
/// of the System Information (type 1) structure.
String? parseSmbiosSystemModel(Uint8List raw) {
  final system = _findSystemInformation(raw);
  if (system == null || system.length < 6) return null;

  // The strings follow the formatted area, each ending with a zero, and
  // the set ends with one more zero. A string number of 0 means no string.
  final strings = <String>[];
  var start = system.offset + system.length;
  for (var i = start; i < system.end && raw[i] != 0; i = start) {
    var stop = i;
    while (stop < system.end && raw[stop] != 0) {
      stop++;
    }
    strings.add(String.fromCharCodes(raw.sublist(i, stop)).trim());
    start = stop + 1;
  }
  String? string(int number) =>
      number == 0 || number > strings.length ? null : strings[number - 1];

  final model = [
    string(raw[system.offset + 4]),
    string(raw[system.offset + 5]),
  ].whereType<String>().where((e) => e.isNotEmpty).join(' ');
  return model.isEmpty ? null : model;
}

({int offset, int length, int end})? _findSystemInformation(Uint8List raw) {
  // RawSMBIOSData: 4 bytes of version info, a 4-byte length, then the table.
  const headerLength = 8;
  if (raw.length < headerLength) return null;
  final tableLength = ByteData.sublistView(
    raw,
  ).getUint32(4, Endian.little);
  final end = math.min(headerLength + tableLength, raw.length);

  var offset = headerLength;
  while (offset + 4 <= end) {
    final type = raw[offset];
    final length = raw[offset + 1];
    if (length < 4 || offset + length > end) return null;

    if (type == 1) return (offset: offset, length: length, end: end);
    if (type == 127) return null; // End-of-table.

    // Skip the formatted area, then the string set ending with two zeros.
    var next = offset + length;
    while (next + 1 < end && (raw[next] != 0 || raw[next + 1] != 0)) {
      next++;
    }
    offset = next + 2;
  }
  return null;
}

String _formatSmbiosUuid(List<int> b) {
  String hex(Iterable<int> bytes) => bytes
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
  return [
    hex([b[3], b[2], b[1], b[0]]),
    hex([b[5], b[4]]),
    hex([b[7], b[6]]),
    hex(b.sublist(8, 10)),
    hex(b.sublist(10, 16)),
  ].join('-');
}
