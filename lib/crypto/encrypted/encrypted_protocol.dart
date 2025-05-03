import 'dart:core';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../../utils/crypto_util.dart';

class EncryptedProtocol {
  List<int> encryptMessage(
    ed.PrivateKey privateKey,
    List<int> plainText,
    List<int> otherPublicKey,
    String otherSessionId,
    List<int>? extensionSessionKey,
    String? extensionSessionId,
  ) {
    final key = generateRandomKey(16);
    final encryptedMessageData = aesGcmEncrypt(key, plainText);
    final messageKey = encryptCipherMessageKey(privateKey, otherPublicKey, key);
    final messageKeyWithSession = [
      ...Uuid.parse(otherSessionId),
      ...messageKey,
    ];

    final senderPublicKey = publicKeyToCurve25519(
      Uint8List.fromList(ed.public(privateKey).bytes),
    );
    final version = [0x01];

    return extensionSessionKey != null && extensionSessionId != null
        ? [
          ...version,
          ...toLeByteArray(2),
          ...senderPublicKey,
          ...Uuid.parse(extensionSessionId),
          ...encryptCipherMessageKey(privateKey, extensionSessionKey, key),
          ...messageKeyWithSession,
          ...encryptedMessageData,
        ]
        : [
          ...version,
          ...toLeByteArray(1),
          ...senderPublicKey,
          ...messageKeyWithSession,
          ...encryptedMessageData,
        ];
  }

  List<int> encryptCipherMessageKey(
    ed.PrivateKey privateKey,
    List<int> otherPublicKey,
    List<int> aesGcmKey,
  ) {
    final private = privateKeyToCurve25519(
      Uint8List.fromList(privateKey.bytes),
    );
    final sharedSecret = calculateAgreement(otherPublicKey, private);
    return aesEncrypt(sharedSecret, aesGcmKey);
  }

  List<int> decryptCipherMessageKey(
    ed.PrivateKey privateKey,
    List<int> otherPublicKey,
    List<int> cipherText,
    List<int> iv,
  ) {
    final private = privateKeyToCurve25519(
      Uint8List.fromList(privateKey.bytes),
    );
    final sharedSecret = calculateAgreement(otherPublicKey, private);
    return aesDecrypt(sharedSecret, iv, cipherText);
  }

  List<int>? decryptMessage(
    ed.PrivateKey privateKey,
    List<int> sessionId,
    List<int> cipherText,
  ) {
    final sessionSize = leByteArrayToInt(cipherText.sublist(1, 3));

    final senderPublicKey = cipherText.sublist(3, 35);
    List<int>? messageKey;
    for (var i = 0; i < sessionSize; ++i) {
      final offset = i * 64;
      final sid = cipherText.sublist(offset + 35, offset + 51);
      if (listEquals(sid, sessionId)) {
        messageKey = cipherText.sublist(offset + 51, offset + 99);
      }
    }
    if (messageKey == null) {
      return null;
    }
    final message = cipherText.sublist(
      35 + sessionSize * 64,
      cipherText.length,
    );

    final iv = messageKey.sublist(0, 16);

    final decodedMessageKey = decryptCipherMessageKey(
      privateKey,
      senderPublicKey,
      messageKey.sublist(16, messageKey.length),
      iv,
    );

    return aesGcmDecrypt(
      decodedMessageKey,
      message.sublist(0, 12),
      message.sublist(12, message.length),
    );
  }
}
