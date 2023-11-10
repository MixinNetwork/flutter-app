import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../utils/db/user_crypto_key_value.dart';
import '../utils/file.dart';

class CryptoKeyValue {
  CryptoKeyValue();

  static const _hiveCrypto = 'crypto_box';
  static const _nextPreKeyId = 'next_pre_key_id';
  static const _nextSignedPreKeyId = 'next_signed_pre_key_id';
  static const _activeSignedPreKeyId = 'active_signed_pre_key_id';

  Future<void> migrateToNewCryptoKeyValue(
    HiveInterface hive,
    String identityNumber,
    UserCryptoKeyValue cryptoKeyValue,
  ) async {
    final directory = Directory(
        p.join(mixinDocumentsDirectory.path, identityNumber, _hiveCrypto));
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      hive.init(directory.absolute.path);
    }
    final exist = await hive.boxExists(_hiveCrypto);
    if (!exist) {
      return;
    }
    final box = await hive.openBox(_hiveCrypto);
    final nextPreKeyId = box.get(_nextPreKeyId, defaultValue: null) as int?;
    final nextSignedPreKeyId =
        box.get(_nextSignedPreKeyId, defaultValue: null) as int?;
    final activeSignedPreKeyId =
        box.get(_activeSignedPreKeyId, defaultValue: null) as int?;
    if (nextPreKeyId != null) {
      await cryptoKeyValue.setNextPreKeyId(nextPreKeyId);
    }
    if (nextSignedPreKeyId != null) {
      await cryptoKeyValue.setNextSignedPreKeyId(nextSignedPreKeyId);
    }
    if (activeSignedPreKeyId != null) {
      await cryptoKeyValue.setActiveSignedPreKeyId(activeSignedPreKeyId);
    }
    await box.deleteFromDisk();
  }
}
