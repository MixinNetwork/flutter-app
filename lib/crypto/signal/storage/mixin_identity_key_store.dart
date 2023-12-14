import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../../utils/logger.dart';
import '../dao/identity_dao.dart';
import '../identity_extension.dart';
import '../signal_database.dart';

class MixinIdentityKeyStore extends IdentityKeyStore {
  MixinIdentityKeyStore(SignalDatabase db, this._accountId) {
    identityDao = IdentityDao(db);
  }

  late IdentityDao identityDao;
  late final String? _accountId;

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async =>
      identityDao
          .getIdentityByAddress(address.toString())
          .then((value) => value?.getIdentityKey());

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async => identityDao
      .getIdentityByAddress('-1')
      .then((value) => value!.getIdentityKeyPair());

  @override
  Future<int> getLocalRegistrationId() async => identityDao
      .getIdentityByAddress('-1')
      .then((value) => value!.registrationId!);

  @override
  Future<bool> isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction direction) async {
    final ourNumber = _accountId;
    if (ourNumber == null) {
      return false;
    }
    final theirAddress = address.getName();
    if (ourNumber == address.getName()) {
      final local = await identityDao
          .getIdentityByAddress('-1')
          .then((value) => value?.getIdentityKey());
      return identityKey == local;
    }
    switch (direction) {
      case Direction.sending:
        return isTrustedForSending(
            identityKey!, await identityDao.getIdentityByAddress(theirAddress));
      case Direction.receiving:
        return true;
    }
  }

  @override
  Future<bool> saveIdentity(
      SignalProtocolAddress address, IdentityKey? identityKey) async {
    final signalAddress = address.getName();
    final identity = await identityDao.getIdentityByAddress(signalAddress);
    if (identity == null) {
      i('Saving new identity...$address');
      await identityDao.insert(IdentitiesCompanion.insert(
          address: signalAddress,
          publicKey: identityKey!.serialize(),
          timestamp: DateTime.now().millisecondsSinceEpoch));
      return true;
    }
    if (identity.getIdentityKey() != identityKey) {
      i('Replacing existing identity...$address');
      await identityDao.insert(IdentitiesCompanion.insert(
          address: signalAddress,
          publicKey: identityKey!.serialize(),
          timestamp: DateTime.now().millisecondsSinceEpoch));
      return true;
    }
    return false;
  }

  bool isTrustedForSending(IdentityKey identityKey, Identity? identity) {
    if (identity == null) {
      i('Nothing here, returning true...');
      return true;
    }
    if (identityKey != identity.getIdentityKey()) {
      i("Identity keys don't match...");
      return false;
    }
    return true;
  }

  Future<void> removeIdentity(SignalProtocolAddress address) async {
    await identityDao.deleteByAddress(address.getName());
  }
}
