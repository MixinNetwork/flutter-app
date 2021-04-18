import 'package:flutter_app/crypto/signal/vo/PreKey.dart';
import 'package:flutter_app/objectbox.g.dart';

class PreKeyDao {
  PreKeyDao(Store store) {
    preKeyBox = store.box<PreKey>();
  }

  late Box<PreKey> preKeyBox;

  PreKey? getPreKeyById(int preKeyId) {
    final query = preKeyBox.query(PreKey_.preKeyId.equals(preKeyId)).build();
    final preKey = query.findFirst();
    query.close();
    return preKey;
  }

  int delete(int preKeyId) {
    final query = preKeyBox.query(PreKey_.preKeyId.equals(preKeyId)).build();
    final count = query.remove();
    query.close();
    return count;
  }

  void insert(PreKey preKey) {
    preKeyBox.put(preKey);
  }
}
