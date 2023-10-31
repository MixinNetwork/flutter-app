import 'package:mixin_logger/mixin_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/hive_key_values.dart';

class SecurityKeyValue extends HiveKeyValue {
  SecurityKeyValue() : super(_hiveSecurity);

  static const _hiveSecurity = 'security_box';
  static const _passcode = 'passcode';
  static const _biometric = 'biometric';
  static const _lockDuration = 'lockDuration';

  String? get passcode {
    try {
      return box.get(_passcode) as String?;
    } catch (e, s) {
      i('[SecurityKeyValue] passcode error: $e, $s');
      return null;
    }
  }

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

  bool get biometric {
    try {
      return box.get(_biometric, defaultValue: false) as bool;
    } catch (e, s) {
      i('[SecurityKeyValue] biometric error: $e, $s');
      return false;
    }
  }

  set biometric(bool value) => box.put(_biometric, value);

  bool get hasPasscode => passcode != null;

  // must be return non-null value
  Duration? get lockDuration {
    dynamic minutes;
    try {
      minutes = box.get(_lockDuration);
    } catch (_) {}
    if (minutes == null) return const Duration(minutes: 1);
    return Duration(minutes: minutes as int);
  }

  set lockDuration(Duration? value) => box.put(_lockDuration, value?.inMinutes);

  Stream<bool> watchHasPasscode() {
    try {
      return box
          .watch(key: _passcode)
          .map((event) => event.value != null)
          .startWith(passcode != null)
          .onErrorReturn(false);
    } catch (e, s) {
      i('[SecurityKeyValue] watchHasPasscode error: $e, $s');
      return Stream.value(false);
    }
  }

  Stream<Duration> watchLockDuration() =>
      box.watch(key: _lockDuration).map((event) {
        final minutes = event.value;
        if (minutes == null) return const Duration(minutes: 1);
        return Duration(minutes: minutes as int);
      });

  Stream<bool> watchBiometric() {
    try {
      return box
          .watch(key: _biometric)
          .map((event) => (event.value ?? false) as bool)
          .onErrorReturn(false);
    } catch (e, s) {
      i('[SecurityKeyValue] watchBiometric error: $e, $s');
      return Stream.value(false);
    }
  }
}
