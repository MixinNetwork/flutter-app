import 'package:flutter_app/crypto/signal/vo/Identity.dart';
import 'package:flutter_app/objectbox.g.dart';

class IdentityDao {
  IdentityDao(Store store) {
    identityBox = store.box<Identity>();
  }

  late Box<Identity> identityBox;

  Identity? getIdentityByAddress(String address) {
    final query =
        identityBox.query(Identity_.address.equals(address.toString())).build();
    final identity = query.findFirst();
    query.close();
    return identity;
  }

  void insert(Identity identity) {
    identityBox.put(identity);
  }

  int delete(String address) {
    final query =
        identityBox.query(Identity_.address.equals(address.toString())).build();
    final count = query.remove();
    query.close();
    return count;
  }
}
