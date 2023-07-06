import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app/utils/crypto/hmac.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculate hmac', () {
    const key = 'eXaxuz9oQ6bgVcdbCJQk16zsDHj9dXcPLFonkz8PTPQ=';
    const source = '123456';
    final result = calculateHMac(
      base64Decode(key),
      Uint8List.fromList(utf8.encode(source)),
    );
    expect(
        base64Encode(result), 'rG0d+pIOti5pPCcTkRsFHmNkD3DJFcGHUqZgOyvIvDc=');
  });
}
