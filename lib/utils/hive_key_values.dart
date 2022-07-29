import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

import '../account/account_key_value.dart';
import '../account/scam_warning_key_value.dart';
import '../account/show_pin_message_key_value.dart';
import '../crypto/crypto_key_value.dart';
import '../crypto/privacy_key_value.dart';
import 'attachment/download_key_value.dart';
import 'file.dart';

Future<void> initKeyValues(String identityNumber) => Future.wait([
      PrivacyKeyValue.instance.init(identityNumber),
      CryptoKeyValue.instance.init(identityNumber),
      AccountKeyValue.instance.init(identityNumber),
      ShowPinMessageKeyValue.instance.init(identityNumber),
      ScamWarningKeyValue.instance.init(identityNumber),
      DownloadKeyValue.instance.init(identityNumber),
    ]);

Future<void> clearKeyValues() => Future.wait([
      PrivacyKeyValue.instance.delete(),
      CryptoKeyValue.instance.delete(),
      AccountKeyValue.instance.delete(),
      ShowPinMessageKeyValue.instance.delete(),
      ScamWarningKeyValue.instance.delete(),
      DownloadKeyValue.instance.delete(),
    ]);

abstract class HiveKeyValue<E> {
  HiveKeyValue(this._boxName);

  final String _boxName;
  late Box<E> box;
  bool _hasInit = false;

  Future init(String identityNumber) async {
    if (_hasInit) {
      return;
    }
    final dbFolder = mixinDocumentsDirectory;

    final legacyBoxDirectory = Directory(p.join(dbFolder.path, _boxName));
    final directory =
        Directory(p.join(dbFolder.path, identityNumber, _boxName));

    if (legacyBoxDirectory.existsSync()) {
      // copy legacy file to new file
      await directory.delete(recursive: true);
      await legacyBoxDirectory.rename(directory.path);
    }

    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      Hive.init(directory.absolute.path);
    }
    box = await Hive.openBox<E>(_boxName);
    _hasInit = true;
  }

  Future delete() async {
    if (!_hasInit) {
      return;
    }
    await Hive.deleteBoxFromDisk(_boxName);
    _hasInit = false;
  }
}
