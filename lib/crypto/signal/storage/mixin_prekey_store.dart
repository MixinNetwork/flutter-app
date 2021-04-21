import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/signal/dao/pre_key_dao.dart';
import 'package:flutter_app/crypto/signal/dao/signed_pre_key_dao.dart';
import 'package:flutter_app/crypto/signal/signal_database.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

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
  void removePreKey(int preKeyId) {
    preKeyDao.deleteByPreKeyId(preKeyId);
  }

  @override
  void storePreKey(int preKeyId, PreKeyRecord record) {
    preKeyDao
        .insert(Prekey(id: 0, prekeyId: preKeyId, record: record.serialize()));
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
    return await signedPreKeyDao.getSignedPreKey(signedPreKeyId) != null;
  }

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
      debugPrint('$e');
    }
    return result;
  }

  @override
  void removeSignedPreKey(int signedPreKeyId) {
    signedPreKeyDao.deleteByPreKeyId(signedPreKeyId);
  }

  @override
  void storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) {
    signedPreKeyDao.insert(SignedPrekey(
        id: 0,
        prekeyId: signedPreKeyId,
        record: record.serialize(),
        timestamp: DateTime.now().millisecondsSinceEpoch));
  }
}
