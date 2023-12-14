import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'address_dao.g.dart';

@DriftAccessor()
class AddressDao extends DatabaseAccessor<MixinDatabase>
    with _$AddressDaoMixin {
  AddressDao(super.db);

  Future<List<Addresses>> getAll() => select(db.addresses).get();

  Future<int> insert(Addresses address) =>
      into(db.addresses).insertOnConflictUpdate(address);

  Future deleteAddress(Addresses address) =>
      delete(db.addresses).delete(address);
}
