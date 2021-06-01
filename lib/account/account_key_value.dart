import '../utils/hive_key_values.dart';

class AccountKeyValue extends HiveKeyValue {
  AccountKeyValue._() : super(_hiveAccount);

  static AccountKeyValue? _instance;

  static AccountKeyValue get instance => _instance ??= AccountKeyValue._();

  static const _hiveAccount = 'account_box';
  static const _hasSyncCircle = 'has_sync_circle';
  static const _refreshStickerLastTime = 'refreshStickerLastTime';
  static const _primarySessionId = 'primarySessionId';

  bool get hasSyncCircle => box.get(_hasSyncCircle, defaultValue: false);
  set hasSyncCircle(bool value) => box.put(_hasSyncCircle, value);

  int get refreshStickerLastTime =>
      box.get(_refreshStickerLastTime, defaultValue: 0);
  set refreshStickerLastTime(int value) =>
      box.put(_refreshStickerLastTime, value);

  String? get primarySessionId =>
      box.get(_primarySessionId, defaultValue: null);
  set primarySessionId(String? value) => box.put(_primarySessionId, value);
}
