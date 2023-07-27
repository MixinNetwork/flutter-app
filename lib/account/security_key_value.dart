import 'package:rxdart/rxdart.dart';

import '../utils/hive_key_values.dart';

class SecurityKeyValue extends HiveKeyValue {
  SecurityKeyValue._() : super(_hiveSecurity);

  static SecurityKeyValue? _instance;

  static SecurityKeyValue get instance => _instance ??= SecurityKeyValue._();

  static const _hiveSecurity = 'security_box';
  static const _passcode = 'passcode';
  static const _biometric = 'biometric';
  static const _lockDuration = 'lockDuration';

  String? get passcode => box.get(_passcode) as String?;

  set passcode(String? value) {
    if (value != null && value.length != 6) {
      throw ArgumentError('Passcode must be 6 digits');
    }
    box.put(_passcode, value);
    if (value == null) {
      lockDuration = null;
      biometric = false;
    }
  }

  bool get biometric => box.get(_biometric, defaultValue: false) as bool;

  set biometric(bool value) => box.put(_biometric, value);

  bool get hasPasscode => passcode != null;

  // must be return non-null value
  Duration? get lockDuration {
    final minutes = box.get(_lockDuration);
    if (minutes == null) return const Duration(minutes: 1);
    return Duration(minutes: minutes as int);
  }

  set lockDuration(Duration? value) => box.put(_lockDuration, value?.inMinutes);

  Stream<bool> watchHasPasscode() => box
      .watch(key: _passcode)
      .map((event) => event.value != null)
      .startWith(passcode != null);

  Stream<Duration> watchLockDuration() =>
      box.watch(key: _lockDuration).map((event) {
        final minutes = event.value;
        if (minutes == null) return const Duration(minutes: 1);
        return Duration(minutes: minutes as int);
      });

  Stream<bool> watchBiometric() =>
      box.watch(key: _biometric).map((event) => (event.value ?? false) as bool);
}
