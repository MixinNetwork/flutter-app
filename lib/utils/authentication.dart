import 'dart:io';

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
      biometricOnly: true,
    );
  } on LocalAuthException catch (error) {
    e('authenticate error code: ${error.code}, message: ${error.description}');
    if (error.code == .authInProgress) {
      await _auth.stopAuthentication();
      return authenticate();
    }
    rethrow;
  }
}
