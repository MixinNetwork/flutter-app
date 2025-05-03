import 'dart:convert';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/encrypted/encrypted_protocol.dart';
import 'package:flutter_app/utils/crypto_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('aseTest', () {
    final source = utf8.encode('mixin');
    final key = generateRandomKey(16);
    final encrypted = aesEncrypt(key, Uint8List.fromList(source));
    final decrypted = aesDecrypt(
      key,
      encrypted.sublist(0, 16),
      encrypted.sublist(16, encrypted.length),
    );
    assert(listEquals(source, decrypted));
  });

  test('gcmAesTest', () {
    final source = utf8.encode('LA');
    final key = generateRandomKey(16);
    final encrypted = aesGcmEncrypt(key, source);
    final decrypted = aesGcmDecrypt(
      key,
      encrypted.sublist(0, 12),
      encrypted.sublist(12, encrypted.length),
    );
    assert(listEquals(source, decrypted));
  });

  test('encryptedTest', () {
    final source = utf8.encode('LA');
    final protocol = EncryptedProtocol();
    final privateKey = ed.generateKey().privateKey;
    final otherKey = ed.generateKey();
    final otherSessionId = const Uuid().v4();
    final pub = publicKeyToCurve25519(
      Uint8List.fromList(otherKey.publicKey.bytes),
    );

    final encodedContent = protocol.encryptMessage(
      privateKey,
      source,
      pub.toList(),
      otherSessionId,
      null,
      null,
    );
    final decrypted = protocol.decryptMessage(
      otherKey.privateKey,
      Uuid.parse(otherSessionId),
      Uint8List.fromList(encodedContent),
    );

    assert(listEquals(source, decrypted));
  });

  test('encryptedWithExtensionTest', () {
    final source = utf8.encode('LA');
    final protocol = EncryptedProtocol();
    final privateKey = ed.generateKey().privateKey;
    final otherKey = ed.generateKey();
    final otherSessionId = const Uuid().v4();
    final pub = publicKeyToCurve25519(
      Uint8List.fromList(otherKey.publicKey.bytes),
    );

    const extensionSessionKey = 'yiPAbfi53jznnt4YUPzbmRjbyoA7cn0KoYxyUVlruxY';
    const extensionSessionId = '93b15f04-3f16-4845-b0c9-acc1314dc8cb';
    final encodedContent = protocol.encryptMessage(
      privateKey,
      source,
      pub.toList(),
      otherSessionId,
      base64.decode(base64.normalize(extensionSessionKey)),
      extensionSessionId,
    );
    final decrypted = protocol.decryptMessage(
      otherKey.privateKey,
      Uuid.parse(otherSessionId),
      Uint8List.fromList(encodedContent),
    );

    assert(listEquals(source, decrypted));
  });

  test('encryptedDecryptTest', () {
    final privateKey = base64Decode(
      'JgW0ffnk+0PN8nJVtfCWZmxv99QIqPw5lquMUov26u0=',
    );
    final encodedContent = base64Decode(
      'AQEApm78Ps6VRCy0MCdUtYGEpBb8bxxaGYkn93pjgaP5RlDr9Z76fkRHmaAUmezSrhV59cj7xD+c9V37wRZPdFVgGTkjhv8FTrj25j/DERttJqIdPnzMLYgWmOA1VJ1PfoE8Jso0liRlFVywvX0ocX+LQw30r454kKsar2oXerP4',
    );

    final sessionId = base64Decode('6/We+n5ER5mgFJns0q4VeQ==');
    final protocol = EncryptedProtocol();
    final decrypted = protocol.decryptMessage(
      ed.PrivateKey(privateKey),
      sessionId,
      Uint8List.fromList(encodedContent),
    );
    assert(listEquals(utf8.encode('LA'), decrypted));
  });

  test('base64RawTest', () {
    const raw = 'MZqwdh6zq6KKfQU6YozSQ4jtAws5UPOJNPSwEBvWUw0';
    base64.decode(base64.normalize(raw));
  });

  test('calculateAgreementTest', () {
    final private = base64.decode(
      'IFxd7LKqNc+NBVhFYqGOyN67J9XXqOzmFu4wBd3YgX0=',
    );
    final public = base64.decode(
      'MZqwdh6zq6KKfQU6YozSQ4jtAws5UPOJNPSwEBvWUw0=',
    );
    final sharedSecret = calculateAgreement(public, private);
    assert(
      'njmQdTN33L/7ZsKuCyPmKu9Q8ywwwpfgSuvT4t8aXQw=' ==
          base64.encode(sharedSecret),
    );
  });

  test('cipherMessageTest', () {
    final protocol = EncryptedProtocol();
    final privateKey = ed.PrivateKey(
      base64.decode('KbGU2ZunXKC43jWPTg1jzxIJRo7KrmVzGc5QSZU0OV8='),
    );
    final otherPublicKey = base64.decode(
      'qZZsBsnxIQgES/FUTMUnbylivOCvgNzg2WnkbS85dVA=',
    );
    final aesGcmKey = base64.decode('t651fSbwBClwHFXiIJ4abg==');
    final encrypted = protocol.encryptCipherMessageKey(
      privateKey,
      otherPublicKey,
      aesGcmKey,
    );
    final decrypted = protocol.decryptCipherMessageKey(
      privateKey,
      otherPublicKey,
      encrypted.sublist(16, encrypted.length),
      encrypted.sublist(0, 16),
    );
    assert(listEquals(aesGcmKey, decrypted));
  });

  test('calculateAgreement', () {
    final senderKey = ed.generateKey();
    final senderPrivate = privateKeyToCurve25519(
      Uint8List.fromList(senderKey.privateKey.bytes),
    );
    final senderPublic = publicKeyToCurve25519(
      Uint8List.fromList(senderKey.publicKey.bytes),
    );

    final receiverKey = ed.generateKey();
    final receiverPrivate = privateKeyToCurve25519(
      Uint8List.fromList(receiverKey.privateKey.bytes),
    );
    final receiverPublic = publicKeyToCurve25519(
      Uint8List.fromList(receiverKey.publicKey.bytes),
    );

    final senderSecret = calculateAgreement(receiverPublic, senderPrivate);

    final receiverSecret = calculateAgreement(senderPublic, receiverPrivate);
    assert(listEquals(senderSecret, receiverSecret));
  });
}
