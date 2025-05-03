import 'package:drift/drift.dart';

import '../signal_database.dart';

part 'pre_key_dao.g.dart';

@DriftAccessor()
class PreKeyDao extends DatabaseAccessor<SignalDatabase> with _$PreKeyDaoMixin {
  PreKeyDao(super.db);

  Future<Prekey?> getPreKeyById(int preKeyId) async =>
      (select(db.prekeys)
        ..where((tbl) => tbl.prekeyId.equals(preKeyId))).getSingleOrNull();

  Future<int> deleteByPreKeyId(int preKeyId) =>
      (delete(db.prekeys)..where((tbl) => tbl.prekeyId.equals(preKeyId))).go();

  Future insert(Prekey preKey) =>
      into(db.prekeys).insert(preKey, mode: InsertMode.insertOrReplace);

  Future insertList(List<PrekeysCompanion> list) async => batch(
    (batch) =>
        batch.insertAll(db.prekeys, list, mode: InsertMode.insertOrReplace),
  );
}
