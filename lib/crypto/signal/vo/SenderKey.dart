import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class SenderKey {
  SenderKey(
    this.groupId,
    this.senderId,
    this.record,
  );

  String groupId;
  String senderId;
  Uint8List record;
}
