import 'package:flutter_app/crypto/signal/vo/SignedPreKey.dart';
import 'package:flutter_app/objectbox.g.dart';

class SignedPreKeyDao {
  SignedPreKeyDao(Store store) {
    signedPreKeyBox = store.box<SignedPreKey>();
  }

  late Box<SignedPreKey> signedPreKeyBox;

  SignedPreKey? getSignedPreKey(int signedPreKeyId) {
    final query = signedPreKeyBox
        .query(SignedPreKey_.preKeyId.equals(signedPreKeyId))
        .build();
    final signedPreKey = query.findFirst();
    query.close();
    return signedPreKey;
  }

  List<SignedPreKey> getSignedPreKeyList() {
    final query = signedPreKeyBox.query().build();
    final signedPreKeys = query.find();
    query.close();
    return signedPreKeys;
  }

  int delete(int signedPreKeyId) {
    final query = signedPreKeyBox
        .query(SignedPreKey_.preKeyId.equals(signedPreKeyId))
        .build();
    final count = query.remove();
    query.close();
    return count;
  }

  void insert(SignedPreKey signedPreKey) {
    signedPreKeyBox.put(signedPreKey);
  }
}
