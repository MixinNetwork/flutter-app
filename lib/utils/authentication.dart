import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../generated/l10n.dart';

final _auth = LocalAuthentication();

Future<bool> checkAuthenticateAvailable() async {
  if (Platform.isWindows) {
    return false;
  }
  final canCheckBiometrics = await _auth.canCheckBiometrics;
  d('auth canCheckBiometrics: $canCheckBiometrics');
  if (!canCheckBiometrics) return false;

  final deviceSupported = await _auth.isDeviceSupported();
  d('auth deviceSupported: $deviceSupported');
  if (!deviceSupported) return false;

  final availableBiometrics = await _auth.getAvailableBiometrics();
  d('auth availableBiometrics: $availableBiometrics');
  if (availableBiometrics.isEmpty) return false;

  return true;
}

Future<bool> authenticate() async {
  try {
    return await _auth.authenticate(
      localizedReason: Localization.current.unlockMixinMessenger,
      options: const AuthenticationOptions(biometricOnly: true),
    );
  } catch (error) {
    if (error is! PlatformException) rethrow;
    e('authenticate error code: ${error.code}, message: ${error.message}');

    switch (error.code) {
      case 'auth_in_progress':
        await _auth.stopAuthentication();
        return authenticate();
      case auth_error.passcodeNotSet:
      case auth_error.notEnrolled:
      case auth_error.notAvailable:
      case auth_error.otherOperatingSystem:
      case auth_error.biometricOnlyNotSupported:
        d('authenticate error code: ${error.code}');
    }

    rethrow;
  }
}
