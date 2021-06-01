// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/util/medium.dart';

import '../utils/crypto_util.dart';
import '../utils/hive_key_values.dart';

class CryptoKeyValue extends HiveKeyValue {
  CryptoKeyValue._() : super(hiveCrypto);

  static CryptoKeyValue? instance;

  static CryptoKeyValue get get => instance ??= CryptoKeyValue._();

  static const hiveCrypto = 'crypto_box';
  static const localRegistrationId = 'local_registration_id';
  static const nextPreKeyId = 'next_pre_key_id';
  static const nextSignedPreKeyId = 'next_signed_pre_key_id';
  static const activeSignedPreKeyId = 'active_signed_pre_key_id';

  int getLocalRegistrationId() => box.get(localRegistrationId, defaultValue: 0);
  void setLocalRegistrationId(int registrationId) =>
      box.put(localRegistrationId, registrationId);

  int getNextPreKeyId() =>
      box.get(nextPreKeyId, defaultValue: generateRandomInt(maxValue));
  void setNextPreKeyId(int preKeyId) => box.put(nextPreKeyId, preKeyId);

  int getNextSignedPreKeyId() =>
      box.get(nextSignedPreKeyId, defaultValue: generateRandomInt(maxValue));
  void setNextSignedPreKeyId(int preKeyId) =>
      box.put(nextSignedPreKeyId, preKeyId);

  int getActiveSignedPreKeyId() =>
      box.get(activeSignedPreKeyId, defaultValue: -1);
  void setActiveSignedPreKeyId(int preKeyId) =>
      box.put(activeSignedPreKeyId, preKeyId);
}
