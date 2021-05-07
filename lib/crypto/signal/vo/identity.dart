import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class Identity {
  Identity(
    this.id,
    this.address,
    this.registrationId,
    this.publicKey,
    this.privateKey,
    this.nextPrekeyId,
    this.date,
  );

  int id;
  String address;
  int? registrationId;
  Uint8List publicKey;
  Uint8List? privateKey;
  int? nextPrekeyId;
  DateTime date;
}
