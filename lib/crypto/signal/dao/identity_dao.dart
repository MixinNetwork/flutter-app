import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'identity_dao.g.dart';

@DriftAccessor(tables: [Identities])
class IdentityDao extends DatabaseAccessor<SignalDatabase>
    with _$IdentityDaoMixin {
  IdentityDao(SignalDatabase db) : super(db);

  Future<Identitie?> getIdentityByAddress(String address) async =>
      (select(db.identities)
            ..where((tbl) => tbl.address.equals(address.toString())))
          .getSingleOrNull();

  Future insert(IdentitiesCompanion identitiesCompanion) => into(db.identities)
      .insert(identitiesCompanion, mode: InsertMode.insertOrReplace);

  Future<int> deleteByAddress(String address) =>
      (delete(db.identities)..where((tbl) => tbl.address.equals(address))).go();

  Future<Identitie?> getLocalIdentity() async =>
      (select(db.identities)..where((tbl) => tbl.address.equals('-1')))
          .getSingleOrNull();
}
