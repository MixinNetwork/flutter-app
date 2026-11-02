import 'dart:typed_data';

import 'package:flutter_app/crypto/attachment/crypto_attachment.dart';
import 'package:flutter_test/flutter_test.dart';

const _chunk = 64 * 1024;

void main() {
  final keys = List<int>.generate(64, (i) => i);
  final iv = List<int>.generate(16, (i) => 100 + i);

  // Sizes around the 64 KiB chunk boundary, including 0.
  for (final size in [
    0,
    1,
    15,
    16,
    17,
    _chunk - 1,
    _chunk,
    _chunk + 1,
    2 * _chunk,
  ]) {
    test('encrypt then decrypt round trips $size bytes', () async {
      final plain = Uint8List.fromList(List.generate(size, (i) => i % 251));
      List<int>? digest;
      final encrypted = <int>[];
      await Stream<List<int>>.value(
        plain,
      ).encrypt(keys, iv, (d) => digest = d).forEach(encrypted.addAll);

      final decrypted = <int>[];
      await Stream<List<int>>.value(
        Uint8List.fromList(encrypted),
      ).decrypt(keys, digest!, encrypted.length).forEach(decrypted.addAll);

      expect(decrypted, plain);
    });
  }
}
