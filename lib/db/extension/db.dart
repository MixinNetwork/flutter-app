import 'package:drift/drift.dart';

extension InsertStatementExt<T extends Table, D> on InsertStatement<T, D> {
  Future<int> simpleInsert(
    Insertable<D> entity, {
    bool updateIfConflict = true,
  }) {
    if (updateIfConflict) {
      return insertOnConflictUpdate(entity);
    } else {
      return insert(entity, mode: InsertMode.insertOrIgnore);
    }
  }
}
