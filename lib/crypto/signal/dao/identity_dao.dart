import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'identity_dao.g.dart';

@DriftAccessor()
class IdentityDao extends DatabaseAccessor<SignalDatabase>
    with _$IdentityDaoMixin {
  IdentityDao(super.db);

  Future<Identity?> getIdentityByAddress(String address) async => (select(
    db.identities,
  )..where((tbl) => tbl.address.equals(address))).getSingleOrNull();

  Future insert(IdentitiesCompanion identitiesCompanion) => into(
    db.identities,
  ).insert(identitiesCompanion, mode: InsertMode.insertOrReplace);

  Future<int> deleteByAddress(String address) =>
      (delete(db.identities)..where((tbl) => tbl.address.equals(address))).go();

  Future<Identity?> getLocalIdentity() async => (select(
    db.identities,
  )..where((tbl) => tbl.address.equals('-1'))).getSingleOrNull();
}
