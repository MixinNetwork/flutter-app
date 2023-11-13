import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../enum/property_group.dart';
import '../crypto_util.dart';
import 'db_key_value.dart';

class UserCryptoKeyValue extends BaseLazyUserKeyValue {
  UserCryptoKeyValue(KeyValueDao<UserPropertyGroup> dao)
      : super(group: UserPropertyGroup.crypto, dao: dao);

  static const _kNextPreKeyId = 'next_pre_key_id';
  static const _kLocalRegistrationId = 'local_registration_id';
  static const _kNextSignedPreKeyId = 'next_signed_pre_key_id';
  static const _kActiveSignedPreKeyId = 'active_signed_pre_key_id';

  Future<int> getNextPreKeyId() async =>
      (await get<int>(_kNextPreKeyId)) ?? generateRandomInt(maxValue);

  Future<void> setNextPreKeyId(int preKeyId) => set(_kNextPreKeyId, preKeyId);

  Future<int> getLocalRegistrationId() async =>
      (await get<int>(_kLocalRegistrationId)) ?? 0;

  Future<void> setLocalRegistrationId(int registrationId) =>
      set(_kLocalRegistrationId, registrationId);

  Future<int> getNextSignedPreKeyId() async =>
      (await get<int>(_kNextSignedPreKeyId)) ?? generateRandomInt(maxValue);

  Future<void> setNextSignedPreKeyId(int preKeyId) =>
      set(_kNextSignedPreKeyId, preKeyId);

  Future<int> getActiveSignedPreKeyId() async =>
      (await get<int>(_kActiveSignedPreKeyId)) ?? -1;

  Future<void> setActiveSignedPreKeyId(int preKeyId) =>
      set(_kActiveSignedPreKeyId, preKeyId);
}
