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
    return parseSmbiosSystemUuid(
      Uint8List.fromList(buffer.asTypedList(written)),
    );
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

    if (type == 1) {
      // The UUID occupies offsets 08h to 17h.
      if (length < 0x18) return null;
      return _formatSmbiosUuid(raw.sublist(offset + 8, offset + 0x18));
    }
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
