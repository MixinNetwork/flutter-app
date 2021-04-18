import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class SignedPreKey {
  SignedPreKey(this.preKeyId, this.record, this.timestamp);

  late int id = 0;
  late int preKeyId;
  late Uint8List record;
  late DateTime timestamp;
}
