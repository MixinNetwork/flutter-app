import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;

import 'file.dart';

Future<void> initKeyValues(String identityNumber) => Future.wait([]);

Future<void> clearKeyValues() => Future.wait([]);

Future<void> disposeKeyValues() => Future.wait([]);

abstract class HiveKeyValue<E> {
  HiveKeyValue(this.boxName);

  final String boxName;
  late Box<E> box;
  bool _hasInit = false;

  String? _identityNumber;

  Future init(String identityNumber) async {
    if (_hasInit) {
      return;
    }
    final dbFolder = mixinDocumentsDirectory;

    final legacyBoxDirectory = Directory(p.join(dbFolder.path, boxName));
    final directory = Directory(p.join(dbFolder.path, identityNumber, boxName));

    if (legacyBoxDirectory.existsSync()) {
      // copy legacy file to new file
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      legacyBoxDirectory.renameSync(directory.path);
    }

    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      Hive.init(directory.absolute.path);
    }
    box = await Hive.openBox<E>(boxName);
    i('HiveKeyValue: open $boxName');
    _identityNumber = identityNumber;
    _hasInit = true;
  }

  Future<void> dispose() async {
    if (!_hasInit) {
      return;
    }
    i('HiveKeyValue: dispose $boxName $_identityNumber');
    await box.close();
    _hasInit = false;
  }

  Future delete() async {
    if (!_hasInit) return;
    try {
      await Hive.deleteBoxFromDisk(boxName);
    } catch (_) {
      // ignore already deleted
    }
    _hasInit = false;
  }
}
