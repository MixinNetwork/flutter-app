import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/crypted_util.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

class EncryptedProtocol {
  List<int> encryptMessage(ed.PrivateKey privateKey, List<int> plainText,
      List<int> otherPublicKey, String otherSessionId) {
    final aesGcmKey = aesGcm.newSecretKeySync(length: 16);
    final encryptedMessageData = aesGcmEncrypt(plainText, aesGcmKey);
    final messageKey = _encryptCipherMessageKey(
        privateKey, otherPublicKey, aesGcmKey.extractSync());
    final messageKeyWithSession = [
      ...Uuid.parse(otherSessionId),
      ...messageKey
    ];

    final senderPublicKey = otherPublicKey;
    final version = [0x01];

    return [
      ...version,
      ...toLeByteArray(1),
      ...senderPublicKey,
      ...messageKeyWithSession,
      ...encryptedMessageData
    ];
  }

  List<int> _encryptCipherMessageKey(
      ed.PrivateKey privateKey, List<int> otherPublicKey, List<int> aesGcmKey) {
    final private =
        privateKeyToCurve25519(Uint8List.fromList(privateKey.bytes));
    final sharedSecret = calculateAgreement(otherPublicKey, private);
    return aesEncrypt(sharedSecret, aesGcmKey);
  }

  List<int> _decryptCipherMessageKey(ed.PrivateKey privateKey,
      List<int> otherPublicKey, List<int> cipherText, List<int> iv) {
    final private =
        privateKeyToCurve25519(Uint8List.fromList(privateKey.bytes));
    final sharedSecret = calculateAgreement(otherPublicKey, private);
    return aesDecrypt(sharedSecret, iv, cipherText);
  }

  List<int>? decryptMessage(
      ed.PrivateKey privateKey, List<int> sessionId, List<int> cipherText) {
    final sessionSize = leByteArrayToInt(cipherText.sublist(1, 3));

    final senderPublicKey = cipherText.sublist(3, 35);
    List<int>? messageKey;
    for (var i = 0; i < sessionSize; ++i) {
      final offset = i * 64;
      final sid = cipherText.sublist(35 + offset, 51 + offset);
      if (listEquals(sid, sessionId)) {
        messageKey = cipherText.sublist(51 + offset, 99 + offset);
      }
    }
    if (messageKey == null) {
      return null;
    }
    final message =
        cipherText.sublist(35 + sessionSize * 64, cipherText.length);

    final iv = messageKey.sublist(0, 16);

    final decodedMessageKey = _decryptCipherMessageKey(privateKey,
        senderPublicKey, messageKey.sublist(16, messageKey.length), iv);

    return aesGcmDecrypt(message, SecretKey(decodedMessageKey));
  }
}
