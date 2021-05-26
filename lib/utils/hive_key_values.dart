import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../account/account_key_value.dart';
import '../crypto/crypto_key_value.dart';
import '../crypto/privacy_key_value.dart';

abstract class HiveKeyValue {
  HiveKeyValue(this._boxName);

  final String _boxName;
  late Box box;
  bool hasInit = false;

  Future init() async {
    if (hasInit) {
      return;
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _boxName));
    await Hive.initFlutter(file.path);
    box = await Hive.openBox(_boxName);
    hasInit = true;
  }

  Future delete() async {
    if (!hasInit) {
      return;
    }
    await Hive.deleteBoxFromDisk(_boxName);
    hasInit = false;
  }

  static Future<void> initKeyValues() async {
    await PrivacyKeyValue.get.init();
    await CryptoKeyValue.get.init();
    await AccountKeyValue.get.init();
  }

  static Future<void> clearKeyValues() async {
    await PrivacyKeyValue.get.delete();
    await CryptoKeyValue.get.delete();
    await AccountKeyValue.get.delete();
  }
}
