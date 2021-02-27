import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/crypted_util.dart';
import 'package:flutter_app/crypto/encrypted/encrypted_protocol.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

void main() {
  aesTest();
  gcmAesTest();
  encryptedTest();
  encryptedDecryptTest();
}

void aesTest() {
  final source = utf8.encode('mixin');
  final aesCbcKey = aesCbc.newSecretKeySync();
  final encrypted = aesEncrypt(aesCbcKey.extractSync(), source);
  final decrypted = aesDecrypt(aesCbcKey.extractSync(),
      encrypted.sublist(0, 16), encrypted.sublist(16, encrypted.length));
  assert(listEquals(source, decrypted));
}

void gcmAesTest() {
  final source = utf8.encode('LA');

  final aesGcmKey = aesGcm.newSecretKeySync();
  final encrypted = aesGcmEncrypt(source, aesGcmKey);

  final decrypted = aesGcmDecrypt(encrypted, aesGcmKey);

  assert(listEquals(source, decrypted));
}

void encryptedTest() {
  final source = utf8.encode('LA');

  final protocol = EncryptedProtocol();
  final privateKey = ed.generateKey().privateKey;
  final otherPublicKey = ed.generateKey().publicKey;
  final otherSessionId = Uuid().v4();
  final pub = publicKeyToCurve25519(Uint8List.fromList(otherPublicKey.bytes));

  final encodedContent =
      protocol.encryptMessage(privateKey, source, pub.toList(), otherSessionId);

  final decrypted =
      protocol.decryptMessage(privateKey, Uint8List.fromList(encodedContent));

  assert(listEquals(source, decrypted));
}

void encryptedDecryptTest() {
  final privateKey =
      base64Decode('JgW0ffnk+0PN8nJVtfCWZmxv99QIqPw5lquMUov26u0=');
  final encodedContent = base64Decode(
      'AQEApm78Ps6VRCy0MCdUtYGEpBb8bxxaGYkn93pjgaP5RlDr9Z76fkRHmaAUmezSrhV59cj7xD+c9V37wRZPdFVgGTkjhv8FTrj25j/DERttJqIdPnzMLYgWmOA1VJ1PfoE8Jso0liRlFVywvX0ocX+LQw30r454kKsar2oXerP4');
  final protocol = EncryptedProtocol();
  final decrypted = protocol.decryptMessage(
      ed.PrivateKey(privateKey), Uint8List.fromList(encodedContent));
  assert(listEquals(utf8.encode('LA'), decrypted));
}
