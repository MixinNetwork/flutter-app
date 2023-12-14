import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'signal_database.dart';

extension IdentityExtension on Identity {
  IdentityKey getIdentityKey() => IdentityKey.fromBytes(publicKey, 0);

  IdentityKeyPair getIdentityKeyPair() => IdentityKeyPair(
      IdentityKey.fromBytes(publicKey, 0),
      Curve.decodePrivatePoint(privateKey!));
}
