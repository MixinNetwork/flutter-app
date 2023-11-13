import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/util/key_helper.dart' as helper;

import '../../utils/db/user_crypto_key_value.dart';
import 'signal_database.dart';
import 'storage/mixin_prekey_store.dart';

const batchSize = 700;

Future<List<PreKeyRecord>> generatePreKeys(
    SignalDatabase database, UserCryptoKeyValue cryptoKeyValue) async {
  final preKeyStore = MixinPreKeyStore(database);
  final preKeyIdOffset = await cryptoKeyValue.getNextPreKeyId();
  final records = helper.generatePreKeys(preKeyIdOffset, batchSize);
  final preKeys = <PrekeysCompanion>[];
  for (final r in records) {
    preKeys.add(PrekeysCompanion.insert(prekeyId: r.id, record: r.serialize()));
  }
  await preKeyStore.storePreKeyList(preKeys);
  await cryptoKeyValue
      .setNextPreKeyId((preKeyIdOffset + batchSize + 1) % maxValue);
  return records;
}

Future<SignedPreKeyRecord> generateSignedPreKey(
    IdentityKeyPair identityKeyPair,
    bool active,
    SignalDatabase database,
    UserCryptoKeyValue cryptoKeyValue) async {
  final signedPreKeyStore = MixinPreKeyStore(database);
  final signedPreKeyId = await cryptoKeyValue.getNextSignedPreKeyId();
  final record = helper.generateSignedPreKey(identityKeyPair, signedPreKeyId);
  await signedPreKeyStore.storeSignedPreKey(signedPreKeyId, record);
  await cryptoKeyValue.setNextSignedPreKeyId((signedPreKeyId + 1) % maxValue);

  if (active) {
    await cryptoKeyValue.setActiveSignedPreKeyId(signedPreKeyId);
  }
  return record;
}
