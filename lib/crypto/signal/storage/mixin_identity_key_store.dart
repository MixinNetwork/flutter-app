import 'package:flutter_app/crypto/signal/dao/identity_dao.dart';
import 'package:flutter_app/crypto/signal/vo/Identity.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

class MixinIdentityKeyStore extends IdentityKeyStore {
  MixinIdentityKeyStore(Store store, this._sessionId) {
    identityDao = IdentityDao(store);
  }

  late IdentityDao identityDao;
  late final String? _sessionId;

  @override
  IdentityKey getIdentity(SignalProtocolAddress address) {
    return identityDao.getIdentityByAddress(address.toString())!.identityKey;
  }

  @override
  IdentityKeyPair getIdentityKeyPair() {
    return identityDao.getIdentityByAddress('-1')!.identityKeyPair;
  }

  @override
  int getLocalRegistrationId() {
    return identityDao.getIdentityByAddress('-1')!.registration_id!;
  }

  @override
  bool isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction direction) {
    final ourNumber = _sessionId;
    if (ourNumber == null) {
      return false;
    }
    final theirAddress = address.getName();
    if (ourNumber == address.getName()) {
      return identityKey == identityDao.getIdentityByAddress('-1')!.identityKey;
    }
    switch (direction) {
      case Direction.SENDING:
        return isTrustedForSending(
            identityKey!, identityDao.getIdentityByAddress(theirAddress));
      case Direction.RECEIVING:
        return true;
      default:
        throw AssertionError('Unknown direction: $direction');
    }
  }

  @override
  bool saveIdentity(SignalProtocolAddress address, IdentityKey? identityKey) {
    final signalAddress = address.getName();
    final identity = identityDao.getIdentityByAddress(address.toString());
    if (identity == null) {
      debugPrint('Saving new identity...$address');
      identityDao.insert(
          Identity(signalAddress, identityKey!.serialize(), DateTime.now()));
      return true;
    } else if (identity.identityKey != identityKey) {
      debugPrint('Replacing existing identity...$address');
      identityDao.insert(
          Identity(signalAddress, identityKey!.serialize(), DateTime.now()));
      return true;
    }
    return false;
  }

  bool isTrustedForSending(IdentityKey identityKey, Identity? identity) {
    if (identity == null) {
      debugPrint('Nothing here, returning true...');
      return true;
    }
    if (identityKey != identity.identityKey) {
      debugPrint('Identity keys don\'t match...');
      return false;
    }
    return false;
  }

  void removeIdentity(SignalProtocolAddress address) {
    identityDao.delete(address.getName());
  }
}
