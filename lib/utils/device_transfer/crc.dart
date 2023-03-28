import 'dart:typed_data';

final _crcTable = Uint32List(256);
const int _polynomial = 0xEDB88320;

void _initCrcTable() {
  for (var i = 0; i < 256; i++) {
    var crc = i;
    for (var j = 0; j < 8; j++) {
      if ((crc & 1) == 1) {
        crc = (crc >> 1) ^ _polynomial;
      } else {
        crc >>= 1;
      }
    }
    _crcTable[i] = crc;
  }
}

int calculateCrc32(Uint8List bytes) {
  if (_crcTable[1] == 0) {
    _initCrcTable();
  }
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
