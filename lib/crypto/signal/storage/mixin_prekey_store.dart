import 'dart:io';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../../utils/logger.dart';
import '../dao/pre_key_dao.dart';
import '../dao/signed_pre_key_dao.dart';
import '../signal_database.dart';

class MixinPreKeyStore implements PreKeyStore, SignedPreKeyStore {
  MixinPreKeyStore(SignalDatabase db) {
    preKeyDao = PreKeyDao(db);
    signedPreKeyDao = SignedPreKeyDao(db);
  }

  late PreKeyDao preKeyDao;
  late SignedPreKeyDao signedPreKeyDao;

  @override
  Future<bool> containsPreKey(int preKeyId) async {
    final preKey = await preKeyDao.getPreKeyById(preKeyId);
    return preKey != null;
  }

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    final preKey = await preKeyDao.getPreKeyById(preKeyId);
    if (preKey == null) {
      throw InvalidKeyIdException('No pre key: $preKeyId');
    }
    return PreKeyRecord.fromBuffer(preKey.record);
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    await preKeyDao.deleteByPreKeyId(preKeyId);
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    await preKeyDao.insert(
      Prekey(id: 0, prekeyId: preKeyId, record: record.serialize()),
    );
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async =>
      await signedPreKeyDao.getSignedPreKey(signedPreKeyId) != null;

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    final signedPreKey = await signedPreKeyDao.getSignedPreKey(signedPreKeyId);
    if (signedPreKey != null) {
      return SignedPreKeyRecord.fromSerialized(signedPreKey.record);
    }
    throw InvalidKeyIdException('No such signed prekey: $signedPreKeyId');
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    final signedPreKeys = await signedPreKeyDao.getSignedPreKeyList();
    final result = <SignedPreKeyRecord>[];
    try {
      for (final signedPreKey in signedPreKeys) {
        result.add(SignedPreKeyRecord.fromSerialized(signedPreKey.record));
      }
    } on IOException catch (e) {
      w('loadSignedPreKeys $e');
    }
    return result;
  }

  @override
  Future removeSignedPreKey(int signedPreKeyId) async {
    await signedPreKeyDao.deleteByPreKeyId(signedPreKeyId);
  }

  @override
  Future storeSignedPreKey(
    int signedPreKeyId,
    SignedPreKeyRecord record,
  ) async {
    await signedPreKeyDao.insert(
      SignedPrekeysCompanion.insert(
        prekeyId: signedPreKeyId,
        record: record.serialize(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future storePreKeyList(List<PrekeysCompanion> list) async {
    await preKeyDao.insertList(list);
  }
}
