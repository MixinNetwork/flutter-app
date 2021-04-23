import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CryptoKeyValue {
  CryptoKeyValue._();

  late Box box;

  static CryptoKeyValue? instance;

  static CryptoKeyValue get get => instance ??= CryptoKeyValue._();

  static const hiveCrypto = 'crypto_box';
  static const localRegistrationId = 'LOCAL_REGISTRATION_ID_PREF';

  Future init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, hiveCrypto));
    await Hive.initFlutter(file.path);
    box = await Hive.openBox(hiveCrypto);
  }

  int getLocalRegistrationId() => box.get(localRegistrationId, defaultValue: 0);

  void setLocalRegistrationId(int registrationId) => box.put(localRegistrationId, registrationId);
}