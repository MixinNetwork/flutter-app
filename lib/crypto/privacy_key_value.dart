import '../utils/hive_key_values.dart';

class PrivacyKeyValue extends HiveKeyValue {
  PrivacyKeyValue._() : super(hivePrivacy);

  static PrivacyKeyValue? instance;

  static PrivacyKeyValue get get => instance ??= PrivacyKeyValue._();

  static const hivePrivacy = 'privacy_box';
  static const hasSyncSession = 'has_sync_session';
  static const hasPushSignalKeys = 'has_push_signal_keys';

  bool getHasSyncSession() => box.get(hasSyncSession, defaultValue: false);

  void setHasSyncSession(bool value) => box.put(hasSyncSession, value);

  bool getHasPushSignalKeys() =>
      box.get(hasPushSignalKeys, defaultValue: false);

  void setHasPushSignalKeys(bool value) => box.put(hasPushSignalKeys, value);
}
