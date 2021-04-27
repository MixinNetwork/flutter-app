import 'dart:io';

import 'package:flutter_app/utils/crypto_util.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/util/Medium.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CryptoKeyValue {
  CryptoKeyValue._();

  late Box box;
  bool hasInit = false;

  static CryptoKeyValue? instance;

  static CryptoKeyValue get get => instance ??= CryptoKeyValue._();

  static const hiveCrypto = 'crypto_box';
  static const localRegistrationId = 'local_registration_id';
  static const nextPreKeyId = 'next_pre_key_id';
  static const nextSignedPreKeyId = 'next_signed_pre_key_id';
  static const activeSignedPreKeyId = 'active_signed_pre_key_id';

  Future init() async {
    if (hasInit) {
      return;
    }
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, hiveCrypto));
    await Hive.initFlutter(file.path);
    box = await Hive.openBox(hiveCrypto);
    hasInit = true;
  }

  int getLocalRegistrationId() => box.get(localRegistrationId, defaultValue: 0);
  void setLocalRegistrationId(int registrationId) =>
      box.put(localRegistrationId, registrationId);

  int getNextPreKeyId() =>
      box.get(nextPreKeyId, defaultValue: generateRandomInt(Medium.MAX_VALUE));
  void setNextPreKeyId(int preKeyId) => box.put(nextPreKeyId, preKeyId);

  int getNextSignedPreKeyId() => box.get(nextSignedPreKeyId,
      defaultValue: generateRandomInt(Medium.MAX_VALUE));
  void setNextSignedPreKeyId(int preKeyId) =>
      box.put(nextSignedPreKeyId, preKeyId);

  int getActiveSignedPreKeyId() =>
      box.get(activeSignedPreKeyId, defaultValue: -1);
  void setActiveSignedPreKeyId(int preKeyId) =>
      box.put(activeSignedPreKeyId, preKeyId);
}
