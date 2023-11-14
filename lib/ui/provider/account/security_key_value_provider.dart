import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../enum/property_group.dart';
import '../../../utils/db/db_key_value.dart';
import '../database_provider.dart';

const _keyPasscode = 'passcode';
const _keyBiometric = 'biometric';
const _keyLockDuration = 'lockDuration';

final securityKeyValueProvider = ChangeNotifierProvider(
  (ref) => SecurityKeyValue(dao: ref.watch(appDatabaseProvider).appKeyValueDao),
);

class SecurityKeyValue extends AppKeyValue {
  SecurityKeyValue({required super.dao})
      : super(group: AppPropertyGroup.setting);

  String? get passcode => get(_keyPasscode);

  set passcode(String? value) => set(_keyPasscode, value);

  bool get biometric => get(_keyBiometric) ?? false;

  set biometric(bool value) => set(_keyBiometric, value);

  bool get hasPasscode => passcode != null;

  Duration get lockDuration => Duration(minutes: get(_keyLockDuration) ?? 1);

  set lockDuration(Duration? value) => set(_keyLockDuration, value?.inMinutes);
}
