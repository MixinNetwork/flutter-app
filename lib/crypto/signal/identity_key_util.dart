import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../crypto_key_value.dart';
import 'identity_extension.dart';
import 'signal_database.dart';

Future<void> generateSignalDatabaseIdentityKeyPair(
  SignalDatabase db,
  List<int>? privateKey,
) async {
  final registrationId = generateRegistrationId(false);
  CryptoKeyValue.instance.localRegistrationId = registrationId;
  final identityKeyPair = privateKey == null
      ? generateIdentityKeyPair()
      : generateIdentityKeyPairFromPrivate(privateKey);
  final identity = IdentitiesCompanion.insert(
      address: '-1',
      registrationId: Value(registrationId),
      publicKey: identityKeyPair.getPublicKey().serialize(),
      privateKey: Value(identityKeyPair.getPrivateKey().serialize()),
      timestamp: DateTime.now().millisecondsSinceEpoch);
  await db.identityDao.insert(identity);
}

Future<IdentityKeyPair?> getIdentityKeyPair(SignalDatabase db) async =>
    db.identityDao
        .getLocalIdentity()
        .then((value) => value?.getIdentityKeyPair());
