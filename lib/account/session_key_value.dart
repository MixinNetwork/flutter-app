import 'dart:convert';
import 'dart:typed_data';

import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../utils/crypto_util.dart';
import '../utils/hive_key_values.dart';
import '../utils/logger.dart';

class SessionKeyValue extends HiveKeyValue {
  SessionKeyValue._() : super('session_box');

  static SessionKeyValue? _instance;

  static SessionKeyValue get instance => _instance ??= SessionKeyValue._();

  static const _keyPinToken = 'pinToken';
  static const _keyPinIterator = 'pinIterator';

  String? get pinToken => box.get(_keyPinToken, defaultValue: null) as String?;

  set pinToken(String? value) => box.put(_keyPinToken, value);

  int get pinIterator => box.get(_keyPinIterator, defaultValue: 1) as int;

  set pinIterator(int value) => box.put(_keyPinIterator, value);

  bool checkPinToken() => pinToken != null && pinToken!.isNotEmpty;
}

List<int> decryptPinToken(String serverPublicKey, ed.PrivateKey privateKey) {
  final bytes = base64Decode(serverPublicKey);
  final private = sdk.privateKeyToCurve25519(
    Uint8List.fromList(privateKey.bytes),
  );
  return calculateAgreement(bytes, private);
}

String? encryptPin(String code) {
  assert(code.isNotEmpty, 'code is empty');
  final iterator = SessionKeyValue.instance.pinIterator;
  final pinToken = SessionKeyValue.instance.pinToken;

  if (pinToken == null) {
    e('pinToken is null');
    return null;
  }

  d('pinToken: $pinToken');

  final pinBytes = Uint8List.fromList(utf8.encode(code));
  final timeBytes = Uint8List(8);
  final iteratorBytes = Uint8List(8);
  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  timeBytes.buffer.asByteData().setUint64(0, nowSec, Endian.little);
  iteratorBytes.buffer.asByteData().setUint64(0, iterator, Endian.little);

  // pin+time+iterator
  final plaintext = Uint8List.fromList(pinBytes + timeBytes + iteratorBytes);
  final ciphertext = aesEncrypt(base64Decode(pinToken), plaintext);

  SessionKeyValue.instance.pinIterator = iterator + 1;

  return base64Encode(ciphertext);
}
