import '../utils/extension/extension.dart';
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
  static const _keyRecentUsedEmoji = 'recentUsedEmoji';
  static const _deviceId = 'deviceId';
  static const _alreadyCleanupQuoteContent = 'alreadyCleanupQuoteContent';

  String? get deviceId => box.get(_deviceId) as String?;

  Future<void> setDeviceId(String value) => box.put(_deviceId, value);

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

  List<String>? _recentUsedEmoji;

  List<String> get recentUsedEmoji => _recentUsedEmoji ??=
      (box.get(_keyRecentUsedEmoji, defaultValue: []) as List).cast<String>();

  bool get alreadyCleanupQuoteContent =>
      box.get(_alreadyCleanupQuoteContent, defaultValue: false) as bool;

  set alreadyCleanupQuoteContent(bool value) =>
      box.put(_alreadyCleanupQuoteContent, value);

  void onEmojiUsed(String emoji) {
    if (recentUsedEmoji.firstOrNull == emoji) {
      return;
    }
    recentUsedEmoji
      ..remove(emoji)
      ..insert(0, emoji);

    while (recentUsedEmoji.length > 35) {
      recentUsedEmoji.removeLast();
    }
    box.put(_keyRecentUsedEmoji, recentUsedEmoji);
  }

  @override
  Future delete() {
    _recentUsedEmoji = null;
    return super.delete();
  }
}
