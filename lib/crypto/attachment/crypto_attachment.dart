import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

import '../../utils/crypto_util.dart';

class CryptoAttachment {
  List<int> decryptAttachment(
      List<int> encryptedBin, List<int> keys, List<int> theirDigest) {
    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);

    final iv = encryptedBin.sublist(0, 16);
    final cipherText = encryptedBin.sublist(16, encryptedBin.length - 32);
    final ivAndCipherText = encryptedBin.sublist(0, encryptedBin.length - 32);
    final mac =
        encryptedBin.sublist(encryptedBin.length - 32, encryptedBin.length);
    final verify = _sign(macKey, ivAndCipherText);
    if (!listEquals(verify, mac)) {
      throw Exception('Verification does not pass');
    }
    return aesDecrypt(aesKey, iv, cipherText);
  }

  List<int> _calculateDigest(List<int> data) {
    final digest = sha256.convert(data);
    return digest.bytes;
  }

  List<int> _sign(List<int> key, List<int> data) {
    final digest = Hmac(sha256, key).convert(data);
    return digest.bytes;
  }

  Tuple2<List<int>, List<int>> encryptAttachment(
      List<int> plainText, List<int> keys, List<int> iv) {
    final aesKey = keys.sublist(0, 32);
    final macKey = keys.sublist(32, 64);
    final ivAndCipherText = aesEncrypt(aesKey, plainText, iv);
    final mac = Hmac(sha256, macKey).convert(ivAndCipherText).bytes;
    final encryptedBin = [...ivAndCipherText, ...mac];
    final digest = _calculateDigest(encryptedBin);
    return Tuple2(encryptedBin, digest);
  }
}
