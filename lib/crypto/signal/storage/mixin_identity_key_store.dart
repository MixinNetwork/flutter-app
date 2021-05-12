import 'package:flutter/foundation.dart';
import 'package:flutter_app/crypto/signal/dao/identity_dao.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../signal_database.dart';
import '../signal_vo_extension.dart';

class MixinIdentityKeyStore extends IdentityKeyStore {
  MixinIdentityKeyStore(SignalDatabase db, this._accountId) {
    identityDao = IdentityDao(db);
  }

  late IdentityDao identityDao;
  late final String? _accountId;

  @override
  Future<IdentityKey> getIdentity(SignalProtocolAddress address) async {
    return identityDao
        .getIdentityByAddress(address.toString())
        .then((value) => value!.getIdentityKey());
  }

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async {
    return identityDao
        .getIdentityByAddress('-1')
        .then((value) => value!.getIdentityKeyPair());
  }

  @override
  Future<int> getLocalRegistrationId() async {
    return identityDao
        .getIdentityByAddress('-1')
        .then((value) => value!.registrationId!);
  }

  @override
  Future<bool> isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction direction) async {
    final ourNumber = _accountId;
    debugPrint('@@@ isTrustedIdentity ourNumber: $ourNumber');
    if (ourNumber == null) {
      return false;
    }
    final theirAddress = address.getName();
    debugPrint('@@@ theirAddress $theirAddress');
    if (ourNumber == address.getName()) {
      debugPrint('@@@ ${identityKey?.publicKey.serialize()}');
      final local = await identityDao
          .getIdentityByAddress('-1')
          .then((value) => value?.getIdentityKey());
      debugPrint('@@@ ${local?.publicKey.serialize()}');
      return identityKey == local;

    }
    debugPrint('@@@ direction: $direction');
    switch (direction) {
      case Direction.SENDING:
        return isTrustedForSending(
            identityKey!, await identityDao.getIdentityByAddress(theirAddress));
      case Direction.RECEIVING:
        return true;
      default:
        throw AssertionError('Unknown direction: $direction');
    }
  }

  @override
  Future<bool> saveIdentity(
      SignalProtocolAddress address, IdentityKey? identityKey) async {
    final signalAddress = address.getName();
    final identity = await identityDao.getIdentityByAddress(signalAddress);
    if (identity == null) {
      debugPrint('Saving new identity...$address');
      await identityDao.insert(IdentitiesCompanion.insert(
          address: signalAddress,
          publicKey: identityKey!.serialize(),
          timestamp: DateTime.now().millisecondsSinceEpoch));
      return true;
    } else if (identity.getIdentityKey() != identityKey) {
      debugPrint('Replacing existing identity...$address');
      await identityDao.insert(IdentitiesCompanion.insert(
          address: signalAddress,
          publicKey: identityKey!.serialize(),
          timestamp: DateTime.now().millisecondsSinceEpoch));
      return true;
    }
    return false;
  }

  bool isTrustedForSending(IdentityKey identityKey, Identitie? identity) {
    if (identity == null) {
      debugPrint('Nothing here, returning true...');
      return true;
    }
    if (identityKey != identity.getIdentityKey()) {
      debugPrint('Identity keys don\'t match...');
      return false;
    }
    return true;
  }

  void removeIdentity(SignalProtocolAddress address) {
    identityDao.deleteByAddress(address.getName());
  }
}
