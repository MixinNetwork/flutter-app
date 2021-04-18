import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class PreKey {
  PreKey(this.preKeyId, this.record);

  late int id = 0;
  late int preKeyId;
  late Uint8List record;
}
