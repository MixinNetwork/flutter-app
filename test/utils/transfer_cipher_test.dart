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

  test('calculate random hMac HMacCalculator.commonCrypto', () async {
    for (var i = 0; i < 100; i++) {
      await _testCalculateRandomHMac(HMacCalculator.commonCrypto);
    }
  }, testOn: 'mac-os');

  test('calculate random hMac HMacCalculator.webCrypto', () async {
    for (var i = 0; i < 100; i++) {
      await _testCalculateRandomHMac(HMacCalculator.webCrypto);
    }
  }, testOn: 'linux');

  test('random encrypt test', () {
    final smallData = Uint8List(1024);
    _randomFillBytes(smallData);
    final key = generateTransferKey();
    _benchMarkAesCipher(
      smallData,
      () {
        final iv = generateTransferIv();
        return AesCipherPointyCastleImpl(
            key: key.aesKey, iv: iv, encrypt: true);
      },
      () {
        final iv = generateTransferIv();
        return AesCipherCommonCryptoImpl(
            key: key.aesKey, iv: iv, encrypt: true);
      },
      count: 1000,
    );

    final largeData = Uint8List(1024 * 1024 * 5);
    _randomFillBytes(largeData);
    _benchMarkAesCipher(
      largeData,
      () {
        final iv = generateTransferIv();
        return AesCipherPointyCastleImpl(
            key: key.aesKey, iv: iv, encrypt: true);
      },
      () {
        final iv = generateTransferIv();
        return AesCipherCommonCryptoImpl(
            key: key.aesKey, iv: iv, encrypt: true);
      },
      count: 5,
    );
  }, testOn: 'mac-os');

  test('random encrypt test', () {
    final smallData = Uint8List(1024);
    _randomFillBytes(smallData);
    final key = generateTransferKey();
    _benchMarkAesCipher(
      smallData,
      () {
        final iv = generateTransferIv();
        return AesCipherPointyCastleImpl(
            key: key.aesKey, iv: iv, encrypt: true);
      },
      () {
        final iv = generateTransferIv();
        return AesCipherWebCryptoImpl(key: key.aesKey, iv: iv, encrypt: true);
      },
      count: 1000,
    );

    final largeData = Uint8List(1024 * 1024 * 5);
    _randomFillBytes(largeData);
    _benchMarkAesCipher(
      largeData,
      () {
        final iv = generateTransferIv();
        return AesCipherPointyCastleImpl(
            key: key.aesKey, iv: iv, encrypt: true);
      },
      () {
        final iv = generateTransferIv();
        return AesCipherWebCryptoImpl(key: key.aesKey, iv: iv, encrypt: true);
      },
      count: 5,
    );
  }, testOn: 'linux||windows');
}

final Random _random = Random.secure();

void _randomFillBytes(List<int> bytes) {
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = _random.nextInt(256);
  }
}

void _benchMarkAesCipher(
  Uint8List data,
  AesCipher Function() cipher1Creator,
  AesCipher Function() cipher2Creator, {
  int count = 10,
}) {
  var cipher1Count = 0;
  var cipher2Count = 0;

  for (var start = 0; start < count; start++) {
    final cipher1 = cipher1Creator();
    final cipher2 = cipher2Creator();

    final stopwatch = Stopwatch()..start();
    cipher1
      ..update(data)
      ..finish();

    final temp = stopwatch.elapsedMicroseconds;
    cipher1Count += temp;

    stopwatch.reset();
    cipher2
      ..update(data)
      ..finish();
    cipher2Count += stopwatch.elapsedMicroseconds;

    i('cipher1 vs cipher2 : $temp : ${stopwatch.elapsedMicroseconds}');
  }

  i('cipher1Count: ${cipher1Count / 1000} ms, cipher2Count: ${cipher2Count / 1000} ms');
}

Future<void> _testCalculateRandomHMac(
    HMacCalculator Function(Uint8List key) creator) async {
  final key = generateTransferKey();

  final calculator1 = creator(key.hMacKey);
  final pointyCastle = HMacCalculator.pointyCastle(key.hMacKey);

  final randomFileSize = math.Random().nextInt(1024 * 1024 * 5);

  final iv = generateTransferIv();
  final aesCipher = AesCipher(key: key.aesKey, iv: iv, encrypt: true);

  calculator1.addBytes(iv);
  pointyCastle.addBytes(iv);

  i('randomFileSize: $randomFileSize');
  final fileStream = _mockFileStream(randomFileSize);

  await for (final bytes in fileStream) {
    final encrypted = aesCipher.update(Uint8List.fromList(bytes));
    calculator1.addBytes(encrypted);
    pointyCastle.addBytes(encrypted);
  }

  final encrypted = aesCipher.finish();
  calculator1.addBytes(encrypted);
  pointyCastle.addBytes(encrypted);

  final commonCryptoResult = calculator1.result;
  final pointyCastleResult = pointyCastle.result;

  i('commonCryptoResult: ${base64Encode(commonCryptoResult)}, '
      'pointyCastleResult: ${base64Encode(pointyCastleResult)}');
  expect(commonCryptoResult, equals(pointyCastleResult));
}

Stream<List<int>> _mockFileStream(int fileSize) async* {
  var left = fileSize;
  while (left > 0) {
    final size = math.min(left, _random.nextInt(1024 * 500));
    left -= size;
    yield generateRandomBytes(size);
  }
  assert(left == 0);
}
