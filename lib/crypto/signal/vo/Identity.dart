import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Identity {
  int id = 0;
  String address;
  int? registration_id;
  Uint8List public_key;
  Uint8List? private_key;
  int? next_prekey_id;
  DateTime date;

  Identity(this.address, this.public_key, this.date,
      {this.registration_id, this.private_key, this.next_prekey_id});

  IdentityKey get identityKey => IdentityKey.fromBytes(public_key, 0);

  IdentityKeyPair get identityKeyPair => IdentityKeyPair(
      IdentityKey.fromBytes(public_key, 0),
      Curve.decodePrivatePoint(private_key!));
}
