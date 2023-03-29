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
  final calculator = CrcCalculator()..addBytes(bytes);
  return calculator.result;
}

class CrcCalculator {
  CrcCalculator() {
    if (_crcTable[1] == 0) {
      _initCrcTable();
    }
  }

  var _crc = 0xFFFFFFFF;

  void addBytes(Uint8List bytes) {
    for (final b in bytes) {
      _crc = _crcTable[(_crc ^ b) & 0xFF] ^ (_crc >> 8);
    }
  }

  int get result => _crc ^ 0xFFFFFFFF;
}
