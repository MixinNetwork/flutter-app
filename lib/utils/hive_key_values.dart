import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../account/account_key_value.dart';
import '../crypto/crypto_key_value.dart';
import '../crypto/privacy_key_value.dart';
import 'file.dart';

abstract class HiveKeyValue {
  HiveKeyValue(this._boxName);

  final String _boxName;
  late Box box;
  bool _hasInit = false;

  Future init() async {
    if (_hasInit) {
      return;
    }
    final dbFolder = mixinDocumentsDirectory;
    final file = File(p.join(dbFolder.path, _boxName));
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      Hive.init(file.absolute.path);
    }
    box = await Hive.openBox(_boxName);
    _hasInit = true;
  }

  Future delete() async {
    if (!_hasInit) {
      return;
    }
    await Hive.deleteBoxFromDisk(_boxName);
    _hasInit = false;
  }

  static Future<void> initKeyValues() async {
    await PrivacyKeyValue.instance.init();
    await CryptoKeyValue.instance.init();
    await AccountKeyValue.instance.init();
  }

  static Future<void> clearKeyValues() async {
    await PrivacyKeyValue.instance.delete();
    await CryptoKeyValue.instance.delete();
    await AccountKeyValue.instance.delete();
  }
}
