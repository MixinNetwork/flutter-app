import 'dart:convert';
import 'dart:typed_data';

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
        key, encrypted.sublist(0, 16), encrypted.sublist(16, encrypted.length));
    assert(listEquals(source, decrypted));
  });

  test('gcmAesTest', () {
    final source = utf8.encode('LA');
    final key = generateRandomKey(16);
    final encrypted = aesGcmEncrypt(key, source);
    final decrypted = aesGcmDecrypt(
        key, encrypted.sublist(0, 12), encrypted.sublist(12, encrypted.length));
    assert(listEquals(source, decrypted));
  });

  test('encryptedTest', () {
    final source = utf8.encode('LA');
    final protocol = EncryptedProtocol();
    final privateKey = ed.generateKey().privateKey;
    final otherPublicKey = ed.generateKey().publicKey;
    final otherSessionId = const Uuid().v4();
    final pub = publicKeyToCurve25519(Uint8List.fromList(otherPublicKey.bytes));

    final encodedContent = protocol.encryptMessage(
        privateKey, source, pub.toList(), otherSessionId);

    final decrypted = protocol.decryptMessage(privateKey,
        Uuid.parse(otherSessionId), Uint8List.fromList(encodedContent));

    assert(listEquals(source, decrypted));
  });

  test('encryptedDecryptTest', () {
    final privateKey =
        base64Decode('JgW0ffnk+0PN8nJVtfCWZmxv99QIqPw5lquMUov26u0=');
    final encodedContent = base64Decode(
        'AQEApm78Ps6VRCy0MCdUtYGEpBb8bxxaGYkn93pjgaP5RlDr9Z76fkRHmaAUmezSrhV59cj7xD+c9V37wRZPdFVgGTkjhv8FTrj25j/DERttJqIdPnzMLYgWmOA1VJ1PfoE8Jso0liRlFVywvX0ocX+LQw30r454kKsar2oXerP4');

    final sessionId = base64Decode('6/We+n5ER5mgFJns0q4VeQ==');
    final protocol = EncryptedProtocol();
    final decrypted = protocol.decryptMessage(ed.PrivateKey(privateKey),
        sessionId, Uint8List.fromList(encodedContent));
    assert(listEquals(utf8.encode('LA'), decrypted));
  });
}
