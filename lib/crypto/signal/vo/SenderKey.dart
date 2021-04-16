import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class SenderKey {
  int id = 0;
  String groupId;
  String senderId;
  Uint8List record;
  SenderKey(this.groupId, this.senderId, this.record);
}
