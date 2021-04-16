import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';


@Entity()
class Identity {
  int id;
  String address;
  int? registration_id;
  Uint8List public_key;
  Uint8List? private_key;
  int? next_prekey_id;
  DateTime date;
  Identity(this.id, this.address, this.registration_id, this.public_key,
      this.private_key, this.next_prekey_id, this.date);
}
