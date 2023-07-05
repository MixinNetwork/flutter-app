import 'package:rxdart/rxdart.dart';

import '../utils/hive_key_values.dart';

class SecurityKeyValue extends HiveKeyValue {
  SecurityKeyValue._() : super(_hiveSecurity);

  static SecurityKeyValue? _instance;

  static SecurityKeyValue get instance => _instance ??= SecurityKeyValue._();

  static const _hiveSecurity = 'security_box';
  static const _passcode = 'passcode';
  static const _biometric = 'biometric';

  String? get passcode => box.get(_passcode) as String?;

  set passcode(String? value) {
    if (value != null && value.length != 6) {
      throw ArgumentError('Passcode must be 6 digits');
    }
    box.put(_passcode, value);
  }

  bool get biometric => box.get(_biometric, defaultValue: false) as bool;

  set biometric(bool value) => box.put(_biometric, value);

  bool get hasPasscode => passcode != null;

  Stream<bool> watchHasPasscode() => box
      .watch(key: _passcode)
      .map((event) => event.value != null)
      .startWith(passcode != null);

  Stream<bool> watchBiometric() =>
      box.watch(key: _biometric).map((event) => (event.value ?? false) as bool);
}
