import 'package:flutter_app/crypto/signal/dao/identity_dao.dart';
import 'package:flutter_app/crypto/signal/vo/Identity.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:objectbox/objectbox.dart';

class MixinIdentityKeyStore extends IdentityKeyStore {
  MixinIdentityKeyStore(Store store) {
    identityDao = IdentityDao(store);
  }

  late IdentityDao identityDao;

  @override
  IdentityKey getIdentity(SignalProtocolAddress address) {
    return identityDao
        .getIdentityByAddress(address.toString())!
        .identityKey; // TODO !
  }

  @override
  IdentityKeyPair getIdentityKeyPair() {
    return identityDao.getIdentityByAddress('-1')!.identityKeyPair; // TODO !
  }

  @override
  int getLocalRegistrationId() {
    return identityDao.getIdentityByAddress('-1')!.registration_id!; // TODO !
  }

  @override
  bool isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction direction) {
    // TODO
    return true;
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
}
