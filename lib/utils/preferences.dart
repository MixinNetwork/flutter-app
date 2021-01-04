import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path_provider/path_provider.dart';

class Preferences {
  Box box;

  Preferences._privateConstructor();

  static final Preferences _instance = Preferences._privateConstructor();

  factory Preferences() => _instance;

  void putAccount(Account account) {
    box.put('account', jsonEncode(account).toString());
  }

  Account getAccount() {
    final String local = box.get('account');
    if (local == null) {
      return null;
    } else {
      return Account.fromJson(jsonDecode(local));
    }
  }

  static Future<void> init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    debugPrint(dbFolder.path);
    Hive.init(dbFolder.path);
    Preferences().box = await Hive.openBox('preferences');
  }
}
