import 'package:drift/drift.dart';

import '../../constants/constants.dart';
import '../mixin_database.dart';

part 'offset_dao.g.dart';

@DriftAccessor()
class OffsetDao extends DatabaseAccessor<MixinDatabase> with _$OffsetDaoMixin {
  OffsetDao(super.db);

  Future<int> insert(Offset offset) =>
      into(db.offsets).insertOnConflictUpdate(offset);

  Future deleteOffset(Offset offset) => delete(db.offsets).delete(offset);

  Selectable<String> findStatusOffset() => (select(
    db.offsets,
  )..where((tbl) => tbl.key.equals(statusOffset))).map((row) => row.timestamp);
}
