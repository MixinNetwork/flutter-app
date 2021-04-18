import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/signal/dao/pre_key_dao.dart';
import 'package:flutter_app/crypto/signal/dao/signed_pre_key_dao.dart';
import 'package:flutter_app/crypto/signal/vo/PreKey.dart';
import 'package:flutter_app/crypto/signal/vo/SignedPreKey.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:objectbox/objectbox.dart';

class MixinPreKeyStore implements PreKeyStore, SignedPreKeyStore {
  MixinPreKeyStore(Store store) {
    preKeyDao = PreKeyDao(store);
    signedPreKeyDao = SignedPreKeyDao(store);
  }

  late PreKeyDao preKeyDao;
  late SignedPreKeyDao signedPreKeyDao;

  @override
  bool containsPreKey(int preKeyId) {
    final preKey = preKeyDao.getPreKeyById(preKeyId);
    return preKey != null;
  }

  @override
  PreKeyRecord loadPreKey(int preKeyId) {
    final preKey = preKeyDao.getPreKeyById(preKeyId);
    if (preKey == null) {
      throw InvalidKeyIdException('No pre key: $preKeyId');
    }
    return PreKeyRecord.fromBuffer(preKey.record);
  }

  @override
  void removePreKey(int preKeyId) {
    preKeyDao.delete(preKeyId);
  }

  @override
  void storePreKey(int preKeyId, PreKeyRecord record) {
    preKeyDao.insert(PreKey(preKeyId, record.serialize()));
  }

  @override
  bool containsSignedPreKey(int signedPreKeyId) {
    return signedPreKeyDao.getSignedPreKey(signedPreKeyId) != null;
  }

  @override
  SignedPreKeyRecord loadSignedPreKey(int signedPreKeyId) {
    final signedPreKey = signedPreKeyDao.getSignedPreKey(signedPreKeyId);
    if (signedPreKey != null) {
      return SignedPreKeyRecord.fromSerialized(signedPreKey.record);
    }
    throw InvalidKeyIdException('No such signed prekey: $signedPreKeyId');
  }

  @override
  List<SignedPreKeyRecord> loadSignedPreKeys() {
    final signedPreKeys = signedPreKeyDao.getSignedPreKeyList();
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
    signedPreKeyDao.delete(signedPreKeyId);
  }

  @override
  void storeSignedPreKey(int signedPreKeyId, SignedPreKeyRecord record) {
    signedPreKeyDao.insert(
        SignedPreKey(signedPreKeyId, record.serialize(), DateTime.now()));
  }
}
