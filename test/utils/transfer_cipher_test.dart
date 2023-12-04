import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/crypto/aes.dart';
import 'package:flutter_app/utils/crypto/hmac.dart';
import 'package:flutter_app/utils/device_transfer/cipher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

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

  test('calculate random hMac', () async {
    final key = generateTransferKey();
    final iv = generateTransferIv();

    i('key: ${key.aesKey} ${key.hMacKey}');
    i('iv: $iv');

    for (var i = 0; i < 100; i++) {
      await _testCalculateRandomHMac();
    }
  }, testOn: 'mac-os');

  test('random encrypt test', () {
    final random = Random.secure();
    for (var start = 0; start < 100; start++) {
      final key = generateTransferKey();
      final iv = generateTransferIv();

      final hMacKey = generateRandomBytes();

      final encryptor =
          AesCipherCommonCryptoImpl(key: key.aesKey, iv: iv, encrypt: true);
      final decryptor =
          AesCipherPointyCastleImpl(key: key.aesKey, iv: iv, encrypt: false);

      final sourceHMac = HMacCalculator(hMacKey);
      final targetHMac = HMacCalculator(hMacKey);

      for (var i = 0; i < 100; i++) {
        final source = generateRandomBytes(random.nextInt(1024));
        sourceHMac.addBytes(source);
        final encrypted = encryptor.update(source);
        targetHMac.addBytes(decryptor.update(encrypted));
      }

      targetHMac
        ..addBytes(decryptor.update(encryptor.finish()))
        ..addBytes(decryptor.finish());

      final sourceResult = sourceHMac.result;
      final targetResult = targetHMac.result;
      i(' sourceResult: ${base64Encode(sourceResult)},'
          ' targetResult: ${base64Encode(targetResult)}');
      expect(base64Encode(sourceResult), equals(base64Encode(targetResult)));
    }
  }, testOn: 'mac-os');
}

Future<void> _testCalculateRandomHMac() async {
  final key = generateTransferKey();

  final commonCrypto = HMacCalculator.commonCrypto(key.hMacKey);
  final pointyCastle = HMacCalculator.pointyCastle(key.hMacKey);

  final randomFileSize = math.Random().nextInt(1024 * 1024 * 5);

  final iv = generateTransferIv();
  final aesCipher =
      AesCipherCommonCryptoImpl(key: key.aesKey, iv: iv, encrypt: true);

  commonCrypto.addBytes(iv);
  pointyCastle.addBytes(iv);

  i('randomFileSize: $randomFileSize');
  final fileStream = _mockFileStream(randomFileSize);

  await for (final bytes in fileStream) {
    final encrypted = aesCipher.update(Uint8List.fromList(bytes));
    commonCrypto.addBytes(encrypted);
    pointyCastle.addBytes(encrypted);
  }

  final encrypted = aesCipher.finish();
  commonCrypto.addBytes(encrypted);
  pointyCastle.addBytes(encrypted);

  final commonCryptoResult = commonCrypto.result;
  final pointyCastleResult = pointyCastle.result;

  i('commonCryptoResult: ${base64Encode(commonCryptoResult)}, '
      'pointyCastleResult: ${base64Encode(pointyCastleResult)}');
  expect(commonCryptoResult, equals(pointyCastleResult));
}

final _random = math.Random.secure();

Stream<List<int>> _mockFileStream(int fileSize) async* {
  var left = fileSize;
  while (left > 0) {
    final size = math.min(left, _random.nextInt(1024 * 500));
    left -= size;
    yield generateRandomBytes(size);
  }
  assert(left == 0);
}
