import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';

import 'package:cryptography/cryptography.dart' as crypto;

List<int> aesGcmEncrypt(List<int> plainText, SecretKey aesKey) {
  final nonce = aesGcm.newNonce();

  final encrypted =
      aesGcm.encryptSync(plainText, secretKey: aesKey, nonce: nonce);

  final result = [...nonce.bytes, ...encrypted];
  return result;
}

Uint8List aesGcmDecrypt(List<int> cipherText, SecretKey aesKey) {
  final nonce = Nonce(cipherText.sublist(0, 12));
  final decrypted = aesGcm.decryptSync(
      Uint8List.fromList(cipherText.sublist(12, cipherText.length)),
      secretKey: aesKey,
      nonce: nonce);
  return decrypted;
}

List<int> aesEncrypt(List<int> key, List<int> plainText, [List<int>? iv]) {
  final cbcCipher = CBCBlockCipher(AESFastEngine());
  final nonce = iv ?? Nonce.randomBytes(16).bytes;
  final ivParams = ParametersWithIV<KeyParameter>(
      KeyParameter(Uint8List.fromList(key)),
      Uint8List.fromList(nonce));
  final paddingParams =
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ivParams, null);

  final paddedCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(true, paddingParams);

  final result = paddedCipher.process(Uint8List.fromList(plainText));

  return [
    ...nonce,
    ...result,
  ];
}

List<int> aesDecrypt(List<int> key, List<int> iv, List<int> cipherText) {
  final cbcCipher = CBCBlockCipher(AESFastEngine());
  final ivParams = ParametersWithIV<KeyParameter>(
      KeyParameter(Uint8List.fromList(key)), Uint8List.fromList(iv));
  final paddingParams =
      PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
          ivParams, null);
  final paddedCipher = PaddedBlockCipherImpl(PKCS7Padding(), cbcCipher)
    ..init(false, paddingParams);
  return paddedCipher.process(Uint8List.fromList(cipherText));
}

List<int> calculateAgreement(List<int> publicKey, List<int> privateKey) {
  if (publicKey == null) {
    throw Exception('publicKey value is null');
  }

  if (privateKey == null) {
    throw Exception('privateKey value is null');
  }

  final secretKey = x25519.sharedSecretSync(
      localPrivateKey: crypto.PrivateKey(privateKey),
      remotePublicKey: crypto.PublicKey(publicKey));
  return secretKey.extractSync();
}

Uint8List toLeByteArray(int v) {
  final result = Uint8List(2);
  result[0] = v;
  result[1] = v >> 8;
  return result;
}

int leByteArrayToInt(List<int> array) {
  return array[0] + array[1];
}
