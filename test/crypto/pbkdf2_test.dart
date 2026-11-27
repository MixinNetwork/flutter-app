import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_app/utils/crypto/pbkdf2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Published PBKDF2-HMAC-SHA256 vectors, so that macOS and Linux agree.
  for (final (iterations, expected) in [
    (1, '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b'),
    (4096, 'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a'),
  ]) {
    test('PBKDF2-HMAC-SHA256 with $iterations iterations', () async {
      final key = await pbkdf2Sha256(
        'password',
        Uint8List.fromList(utf8.encode('salt')),
        iterations,
      );

      expect(hex.encode(key), expected);
    });
  }
}
