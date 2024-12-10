import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'address_dao.g.dart';

@DriftAccessor()
class AddressDao extends DatabaseAccessor<MixinDatabase>
    with _$AddressDaoMixin {
  AddressDao(super.db);

  Future<List<Address>> getAll() => select(db.addresses).get();

  Future<int> insert(Address address) =>
      into(db.addresses).insertOnConflictUpdate(address);

  Future deleteAddress(Address address) => delete(db.addresses).delete(address);
}
