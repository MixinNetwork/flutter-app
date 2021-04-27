import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PrivacyKeyValue {
  PrivacyKeyValue._();

  late Box box;
  bool hasInit = false;

  static PrivacyKeyValue? instance;

  static PrivacyKeyValue get get => instance ??= PrivacyKeyValue._();

  static const hivePrivacy = 'privacy_box';
  static const hasSyncSession = 'has_sync_session';
  static const hasPushSignalKeys = 'has_push_signal_keys';

  Future init() async {
    if (hasInit) {
      return;
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, hivePrivacy));
    await Hive.initFlutter(file.path);
    box = await Hive.openBox(hivePrivacy);
    hasInit = true;
  }

  bool getHasSyncSession() => box.get(hasSyncSession, defaultValue: false);
  void setHasSyncSession(bool value) => box.put(hasSyncSession, value);

  bool getHasPushSignalKeys() =>
      box.get(hasPushSignalKeys, defaultValue: false);
  void setHasPushSignalKeys(bool value) => box.put(hasPushSignalKeys, value);
}
