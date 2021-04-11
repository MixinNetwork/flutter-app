import 'dart:typed_data';

class SenderKey {
  String groupId;
  String senderId;
  Uint8List record;
  SenderKey(this.groupId, this.senderId, this.record);
}
