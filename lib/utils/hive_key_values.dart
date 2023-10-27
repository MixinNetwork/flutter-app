import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;

import '../account/scam_warning_key_value.dart';
import '../account/security_key_value.dart';
import '../account/session_key_value.dart';
import '../account/show_pin_message_key_value.dart';
import '../crypto/privacy_key_value.dart';
import 'attachment/download_key_value.dart';
import 'file.dart';

Future<void> initKeyValues(String identityNumber) => Future.wait([
      PrivacyKeyValue.instance.init(identityNumber),
      ShowPinMessageKeyValue.instance.init(identityNumber),
      ScamWarningKeyValue.instance.init(identityNumber),
      DownloadKeyValue.instance.init(identityNumber),
      SessionKeyValue.instance.init(identityNumber),
      SecurityKeyValue.instance.init(identityNumber),
    ]);

Future<void> clearKeyValues() => Future.wait([
      PrivacyKeyValue.instance.delete(),
      ShowPinMessageKeyValue.instance.delete(),
      ScamWarningKeyValue.instance.delete(),
      DownloadKeyValue.instance.delete(),
      SessionKeyValue.instance.delete(),
      SecurityKeyValue.instance.delete(),
    ]);

Future<void> disposeKeyValues() => Future.wait([
      PrivacyKeyValue.instance.dispose(),
      ShowPinMessageKeyValue.instance.dispose(),
      ScamWarningKeyValue.instance.dispose(),
      DownloadKeyValue.instance.dispose(),
      SessionKeyValue.instance.dispose(),
      SecurityKeyValue.instance.dispose(),
    ]);

abstract class HiveKeyValue<E> {
  HiveKeyValue(this._boxName);

  final String _boxName;
  late Box<E> box;
  bool _hasInit = false;

  String? _identityNumber;

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
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      legacyBoxDirectory.renameSync(directory.path);
    }

    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      Hive.init(directory.absolute.path);
    }
    box = await Hive.openBox<E>(_boxName);
    i('HiveKeyValue: open $_boxName');
    _identityNumber = identityNumber;
    _hasInit = true;
  }

  Future<void> dispose() async {
    if (!_hasInit) {
      return;
    }
    i('HiveKeyValue: dispose $_boxName $_identityNumber');
    await box.close();
    _hasInit = false;
  }

  Future delete() async {
    if (!_hasInit) return;
    try {
      await Hive.deleteBoxFromDisk(_boxName);
    } catch (_) {
      // ignore already deleted
    }
    _hasInit = false;
  }
}
