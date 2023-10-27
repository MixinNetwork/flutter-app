// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/util/medium.dart';

import '../utils/crypto_util.dart';
import '../utils/hive_key_values.dart';

class CryptoKeyValue extends HiveKeyValue<int> {
  CryptoKeyValue() : super(_hiveCrypto);

  static const _hiveCrypto = 'crypto_box';
  static const _localRegistrationId = 'local_registration_id';
  static const _nextPreKeyId = 'next_pre_key_id';
  static const _nextSignedPreKeyId = 'next_signed_pre_key_id';
  static const _activeSignedPreKeyId = 'active_signed_pre_key_id';

  int get localRegistrationId =>
      box.get(_localRegistrationId, defaultValue: 0)!;

  set localRegistrationId(int registrationId) =>
      box.put(_localRegistrationId, registrationId);

  int get nextPreKeyId =>
      box.get(_nextPreKeyId, defaultValue: generateRandomInt(maxValue))!;

  set nextPreKeyId(int preKeyId) => box.put(_nextPreKeyId, preKeyId);

  int get nextSignedPreKeyId =>
      box.get(_nextSignedPreKeyId, defaultValue: generateRandomInt(maxValue))!;

  set nextSignedPreKeyId(int preKeyId) =>
      box.put(_nextSignedPreKeyId, preKeyId);

  int get activeSignedPreKeyId =>
      box.get(_activeSignedPreKeyId, defaultValue: -1)!;

  set activeSignedPreKeyId(int preKeyId) =>
      box.put(_activeSignedPreKeyId, preKeyId);
}
