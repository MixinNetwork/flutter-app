import '../utils/hive_key_values.dart';

class PrivacyKeyValue extends HiveKeyValue<bool> {
  PrivacyKeyValue() : super(_hivePrivacy);

  static const _hivePrivacy = 'privacy_box';
  static const _hasSyncSession = 'has_sync_session';
  static const _hasPushSignalKeys = 'has_push_signal_keys';

  bool get hasSyncSession => box.get(_hasSyncSession, defaultValue: false)!;

  set hasSyncSession(bool value) => box.put(_hasSyncSession, value);

  bool get hasPushSignalKeys =>
      box.get(_hasPushSignalKeys, defaultValue: false)!;

  set hasPushSignalKeys(bool value) => box.put(_hasPushSignalKeys, value);
}
