import 'package:hive/hive.dart';

late Box globalBox;

Future<void> initGlobalHive() async {
  globalBox = await Hive.openBox('global');
}
