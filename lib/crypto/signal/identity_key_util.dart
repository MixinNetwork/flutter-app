import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:moor/moor.dart';

import '../crypto_key_value.dart';
import 'signal_database.dart';
import 'signal_vo_extension.dart';

class IdentityKeyUtil {
  static Future<void> generateIdentityKeyPair(
      SignalDatabase db, List<int> privateKey) async {
    final registrationId = generateRegistrationId(false);
    CryptoKeyValue.instance.localRegistrationId = registrationId;
    final identityKeyPair = generateIdentityKeyPairFromPrivate(privateKey);
    final identity = IdentitiesCompanion.insert(
        address: '-1',
        registrationId: Value(registrationId),
        publicKey: identityKeyPair.getPublicKey().serialize(),
        privateKey: Value(identityKeyPair.getPrivateKey().serialize()),
        timestamp: DateTime.now().millisecondsSinceEpoch);
    await db.identityDao.insert(identity);
  }

  static Future<IdentityKeyPair?> getIdentityKeyPair(SignalDatabase db) async =>
      db.identityDao
          .getLocalIdentity()
          .then((value) => value?.getIdentityKeyPair());
}
