// import 'package:flutter_app/crypto/db/signal_database_helper.dart';
// import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// import '../vo/identity.dart';

// TODO
// class MixinIdentityKeyStore extends IdentityKeyStore {
//   var identityDao = SignalDatabaseHelper.instance.database;
//
//   @override
//   IdentityKey getIdentity(SignalProtocolAddress address) {
//     var identity = identityDao.getIdentity(address.toString()).getSingle();
//     // return await identity.getIdentityKey();
//   }
//
//   @override
//   IdentityKeyPair getIdentityKeyPair() {
//     // TODO: implement getIdentityKeyPair
//     throw UnimplementedError();
//   }
//
//   @override
//   int getLocalRegistrationId() {
//     // TODO: implement getLocalRegistrationId
//     throw UnimplementedError();
//   }
//
//   @override
//   bool isTrustedIdentity(SignalProtocolAddress address, IdentityKey identityKey,
//       Direction direction) {
//     // TODO: implement isTrustedIdentity
//     throw UnimplementedError();
//   }
//
//   @override
//   bool saveIdentity(SignalProtocolAddress address, IdentityKey identityKey) {
//     // TODO: implement saveIdentity
//     throw UnimplementedError();
//   }
// }
