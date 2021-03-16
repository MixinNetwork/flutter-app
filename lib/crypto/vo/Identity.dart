import 'package:flutter_app/crypto/db/signal_database.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

extension IdentityExtension on Identity {
  IdentityKeyPair getIdentityKeyPair() {
    final publicKey = IdentityKey.fromBytes(this.publicKey, 0);
    final privateKey = Curve.decodePrivatePoint(this.privateKey!);
    return IdentityKeyPair(publicKey, privateKey);
  }

  IdentityKey getIdentityKey() {
    return IdentityKey.fromBytes(publicKey, 0);
  }
}
