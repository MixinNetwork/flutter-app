import 'package:flutter_app/crypto/crypto_key_value.dart';
import 'package:flutter_app/crypto/signal/signal_database.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/util/Medium.dart';

import 'storage/mixin_prekey_store.dart';

class PreKeyUtil {
  static const batchSize = 700;

  static Future<List<PreKeyRecord>> generatePreKeys() async {
    final preKeyStore = MixinPreKeyStore(SignalDatabase.get);
    final preKeyIdOffset = CryptoKeyValue.get.getNextPreKeyId();
    final records = KeyHelper.generatePreKeys(preKeyIdOffset, batchSize);
    final preKeys = <PrekeysCompanion>[];
    for (final r in records) {
      preKeys
          .add(PrekeysCompanion.insert(prekeyId: r.id, record: r.serialize()));
    }
    await preKeyStore.storePreKeyList(preKeys);
    CryptoKeyValue.get
        .setNextPreKeyId((preKeyIdOffset + batchSize + 1) % Medium.MAX_VALUE);
    return records;
  }

  static Future<SignedPreKeyRecord> generateSignedPreKey(
      IdentityKeyPair identityKeyPair, bool active) async {
    final signedPreKeyStore = MixinPreKeyStore(SignalDatabase.get);
    final signedPreKeyId = CryptoKeyValue.get.getNextSignedPreKeyId();
    final record =
        KeyHelper.generateSignedPreKey(identityKeyPair, signedPreKeyId);
    await signedPreKeyStore.storeSignedPreKey(signedPreKeyId, record);
    CryptoKeyValue.get
        .setNextSignedPreKeyId((signedPreKeyId + 1) % Medium.MAX_VALUE);

    if (active) {
      CryptoKeyValue.get.setActiveSignedPreKeyId(signedPreKeyId);
    }
    return record;
  }
}
