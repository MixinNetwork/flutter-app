import '../utils/hive_key_values.dart';

class AccountKeyValue extends HiveKeyValue {
  AccountKeyValue._() : super(hiveAccount);

  static AccountKeyValue? instance;

  static AccountKeyValue get get => instance ??= AccountKeyValue._();

  static const hiveAccount = 'account_box';
  static const hasSyncCircle = 'has_sync_circle';
  static const refreshStickerLastTime = 'refreshStickerLastTime';
  static const primarySessionId = 'primarySessionId';

  bool getHasSyncCircle() => box.get(hasSyncCircle, defaultValue: false);
  void setHasSyncCircle(bool value) => box.put(hasSyncCircle, value);

  int getRefreshStickerLastTime() =>
      box.get(refreshStickerLastTime, defaultValue: 0);
  void setRefreshStickerLastTime(int value) =>
      box.put(refreshStickerLastTime, value);

  String? getPrimarySessionId() =>
      box.get(primarySessionId, defaultValue: null);
  void setPrimarySessionId(String value) => box.put(primarySessionId, value);
}
