import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:mixin_logger/mixin_logger.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/crypto/pbkdf2.dart';
import '../utils/crypto_util.dart';
import '../utils/hive_key_values.dart';

class SecurityKeyValue extends HiveKeyValue {
  SecurityKeyValue._() : super(_hiveSecurity);

  static SecurityKeyValue? _instance;

  static SecurityKeyValue get instance => _instance ??= SecurityKeyValue._();

  static const _hiveSecurity = 'security_box';
  // Plain text, written by earlier versions.
  static const _plainPasscode = 'passcode';
  // "<salt>:<PBKDF2-SHA256 of the passcode>", both base64.
  static const _passcodeVerifier = 'passcodeVerifier';
  static const _biometric = 'biometric';
  static const _lockDuration = 'lockDuration';

  // OWASP password storage guidance for PBKDF2-HMAC-SHA256.
  static const _iterations = 600000;

  @override
  Future<void> init(String identityNumber) async {
    await super.init(identityNumber);
    final plain = box.get(_plainPasscode);
    if (plain is String) await setPasscode(plain);
    // Hive appends to its file, so a deleted value stays until it compacts.
    // Every start does this, also after a run that stopped before it did.
    await box.compact();
  }

  Future<void> setPasscode(String? value) async {
    if (value == null) {
      await box.deleteAll([_passcodeVerifier, _plainPasscode]);
      lockDuration = null;
      biometric = false;
    } else {
      if (value.length != 6) {
        throw ArgumentError('Passcode must be 6 digits');
      }
      final salt = Uint8List.fromList(generateRandomKey(16));
      final hash = await pbkdf2Sha256(value, salt, _iterations);
      await box.put(
        _passcodeVerifier,
        '${base64Encode(salt)}:${base64Encode(hash)}',
      );
      await box.delete(_plainPasscode);
    }
  }

  Future<bool> verifyPasscode(String value) async {
    final verifier = box.get(_passcodeVerifier) as String?;
    if (verifier == null) return false;
    final [salt, hash] = verifier.split(':');
    return listEquals(
      await pbkdf2Sha256(value, base64Decode(salt), _iterations),
      base64Decode(hash),
    );
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

  // Also true while a plain passcode waits for its replacement.
  // Signing out closes the box while the lock screen guard is mounted.
  bool get hasPasscode =>
      box.isOpen &&
      (box.containsKey(_passcodeVerifier) || box.containsKey(_plainPasscode));

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
          .watch(key: _passcodeVerifier)
          .map((event) => event.value != null)
          .startWith(hasPasscode)
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
