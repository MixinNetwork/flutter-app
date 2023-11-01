import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'safe_snapshot_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/safe_snapshot.drift'})
class SafeSnapshotDao extends DatabaseAccessor<MixinDatabase>
    with _$SafeSnapshotDaoMixin {
  SafeSnapshotDao(super.db);

  Future<int> insert(SafeSnapshot snapshot) =>
      into(db.safeSnapshots).insertOnConflictUpdate(snapshot);

  Future<List<SafeSnapshot>> snapshotItem(String assetId) =>
      (select(db.safeSnapshots)..where((tbl) => tbl.assetId.equals(assetId)))
          .get();
}
