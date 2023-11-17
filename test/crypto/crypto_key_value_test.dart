@TestOn('linux || mac-os')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_app/crypto/crypto_key_value.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/db/user_crypto_key_value.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;

void main() {
  late MixinDatabase database;
  late HiveInterface hive;

  setUp(() {
    database = MixinDatabase(NativeDatabase.memory());
    mixinDocumentsDirectory = Directory(p.join(
      Directory.systemTemp.path,
      'mixin_test_hive',
    ));
    // remove all data
    try {
      if (mixinDocumentsDirectory.existsSync()) {
        mixinDocumentsDirectory.deleteSync(recursive: true);
      }
    } catch (error, stackTrace) {
      e('delete hive path error: $error, $stackTrace');
    }
    mixinDocumentsDirectory.createSync(recursive: true);
    hive = HiveImpl();
  });

  tearDown(() async {
    await database.close();
  });

  test('no migration', () async {
    final oldCryptoKeyValue = CryptoKeyValue();
    final cryptoKeyValue = UserCryptoKeyValue(database.propertyDao);
    await oldCryptoKeyValue.migrateToNewCryptoKeyValue(
        hive, 'test', cryptoKeyValue);
    expect(await cryptoKeyValue.get<int>('next_pre_key_id'), null);
    expect(await cryptoKeyValue.get<int>('next_signed_pre_key_id'), null);
    expect(await cryptoKeyValue.get<int>('active_signed_pre_key_id'), null);
  });

  test('migration', () async {
    final oldCryptoKeyValue = CryptoKeyValue();
    final cryptoKeyValue = UserCryptoKeyValue(database.propertyDao);
    hive.init(p.join(mixinDocumentsDirectory.path, 'test', 'crypto_box'));
    final box = await hive.openBox('crypto_box');
    await box.put('next_pre_key_id', 1);
    await box.put('next_signed_pre_key_id', 2);
    await box.put('active_signed_pre_key_id', 3);
    await oldCryptoKeyValue.migrateToNewCryptoKeyValue(
        hive, 'test', cryptoKeyValue);
    expect(await cryptoKeyValue.get<int>('next_pre_key_id'), 1);
    expect(await cryptoKeyValue.get<int>('next_signed_pre_key_id'), 2);
    expect(await cryptoKeyValue.get<int>('active_signed_pre_key_id'), 3);
  });
}
