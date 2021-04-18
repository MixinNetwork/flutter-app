import 'package:flutter_app/crypto/signal/vo/SenderKey.dart';
import 'package:flutter_app/objectbox.g.dart';

class SenderKeyDao {
  SenderKeyDao(Store store) {
    senderKeyBox = store.box<SenderKey>();
  }

  late Box<SenderKey> senderKeyBox;

  SenderKey? getSenderKey(String groupId, String senderId) {
    final query = senderKeyBox
        .query(SenderKey_.groupId
            .equals(groupId)
            .and(SenderKey_.senderId.equals(senderId)))
        .build();
    final senderKey = query.findFirst();
    query.close();
    return senderKey;
  }

  int delete(String groupId, String senderId) {
    final query = senderKeyBox
        .query(SenderKey_.groupId
            .equals(groupId)
            .and(SenderKey_.senderId.equals(senderId)))
        .build();
    final count = query.remove();
    query.close();
    return count;
  }

  List<SenderKey> getSenderKeys() {
    final query = senderKeyBox.query().build();
    final senderKeys = query.find();
    query.close();
    return senderKeys;
  }

  void insert(SenderKey senderKey) {
    senderKeyBox.put(senderKey);
  }
}
