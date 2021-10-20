import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'address_dao.g.dart';

@DriftAccessor(tables: [Addresses])
class AddressDao extends DatabaseAccessor<MixinDatabase>
    with _$AddressDaoMixin {
  AddressDao(MixinDatabase db) : super(db);

  Future<List<Addresse>> getAll() => select(db.addresses).get();

  Future<int> insert(Addresse address) =>
      into(db.addresses).insertOnConflictUpdate(address);

  Future deleteAddress(Addresse address) =>
      delete(db.addresses).delete(address);
}
