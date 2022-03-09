import '../utils/hive_key_values.dart';

class AccountKeyValue extends HiveKeyValue {
  AccountKeyValue._() : super(_hiveAccount);

  static AccountKeyValue? _instance;

  static AccountKeyValue get instance => _instance ??= AccountKeyValue._();

  static const _hiveAccount = 'account_box';
  static const _hasSyncCircle = 'has_sync_circle';
  static const _refreshStickerLastTime = 'refreshStickerLastTime';
  static const _primarySessionId = 'primarySessionId';
  static const _hasNewAlbum = 'hasNewAlbum';
  static const _checkUpdateLastTime = 'checkUpdateLastTime';
  static const _ignoredVersion = '_ignoredVersion';

  bool get hasSyncCircle =>
      box.get(_hasSyncCircle, defaultValue: false) as bool;

  set hasSyncCircle(bool value) => box.put(_hasSyncCircle, value);

  int get refreshStickerLastTime =>
      box.get(_refreshStickerLastTime, defaultValue: 0) as int;

  set refreshStickerLastTime(int value) =>
      box.put(_refreshStickerLastTime, value);

  String? get primarySessionId =>
      box.get(_primarySessionId, defaultValue: null) as String?;

  set primarySessionId(String? value) => box.put(_primarySessionId, value);

  bool get hasNewAlbum => box.get(_hasNewAlbum, defaultValue: false) as bool;

  set hasNewAlbum(bool value) => box.put(_hasNewAlbum, value);

  int get checkUpdateLastTime =>
      box.get(_checkUpdateLastTime, defaultValue: 0) as int;

  set checkUpdateLastTime(int value) => box.put(_checkUpdateLastTime, value);

  String? get ignoredVersion =>
      box.get(_ignoredVersion, defaultValue: '0.0.0') as String?;

  set ignoredVersion(String? value) => box.put(_ignoredVersion, value);
}
