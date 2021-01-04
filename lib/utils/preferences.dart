import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class Preferences {
  Box box;

  Preferences._privateConstructor();

  static final Preferences _instance = Preferences._privateConstructor();

  factory Preferences() => _instance;

  void putAccount(String string) {
    box.put('account', string);
  }

  String getAccount() {
    return box.get('account');
  }

  static Future<void> init() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    debugPrint(dbFolder.path);
    Hive.init(dbFolder.path);
    Preferences().box = await Hive.openBox('preferences');
  }
}
