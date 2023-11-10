import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:path/path.dart' as p;

import 'file.dart';

abstract class HiveKeyValue<E> {
  HiveKeyValue(this.boxName);

  final String boxName;
  late Box<E> box;
  bool _hasInit = false;

  String? _identityNumber;

  Future init(HiveInterface hive, String identityNumber) async {
    if (_hasInit) {
      return;
    }
    final dbFolder = mixinDocumentsDirectory;
    final directory = Directory(p.join(dbFolder.path, identityNumber, boxName));
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      hive.init(directory.absolute.path);
    }
    box = await hive.openBox<E>(boxName);
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

  Future<void> clear() async {
    if (!_hasInit) {
      return;
    }
    i('HiveKeyValue: clear $boxName $_identityNumber');
    await box.clear();
  }

  @override
  String toString() =>
      'HiveKeyValue{boxName: $boxName, _hasInit: $_hasInit, _identityNumber: $_identityNumber}';
}
