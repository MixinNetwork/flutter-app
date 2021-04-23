import 'package:flutter_app/crypto/crypto_key_value.dart';
import 'package:flutter_app/crypto/signal/signal_database.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:moor/moor.dart';
import 'signal_vo_extension.dart';

class IdentityKeyUtil {
  static Future generateIdentityKeyPair(SignalDatabase db) async {
    final registrationId = KeyHelper.generateRegistrationId(false);
    CryptoKeyValue.get.setLocalRegistrationId(registrationId);
    final identityKeyPair = KeyHelper.generateIdentityKeyPair();
    final identity = IdentitiesCompanion.insert(
        address: '-1',
        registrationId: Value(registrationId),
        publicKey: identityKeyPair.getPublicKey().serialize(),
        privateKey: Value(identityKeyPair.getPrivateKey().serialize()),
        timestamp: DateTime.now().millisecondsSinceEpoch);
    await db.identityDao.insert(identity);
  }

  static Future<IdentityKeyPair> getIdentityKeyPair(SignalDatabase db) async =>
      db.identityDao
          .getLocalIdentity()
          .then((value) => value.getIdentityKeyPair());
}
