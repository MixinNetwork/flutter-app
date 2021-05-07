import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class SignedPreKey {
  late int id;
  late int preKeyId;
  late Uint8List record;
  late DateTime timestamp;
}
