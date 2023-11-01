import 'package:drift/drift.dart';

import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';

part 'safe_snapshot_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/safe_snapshot.drift'})
class SafeSnapshotDao extends DatabaseAccessor<MixinDatabase>
    with _$SafeSnapshotDaoMixin {
  SafeSnapshotDao(super.db);

  Future<int> insert(SafeSnapshot snapshot, {bool updateIfConflict = true}) =>
      into(db.safeSnapshots)
          .simpleInsert(snapshot, updateIfConflict: updateIfConflict)
          .then((value) async {
        if (value > 0) {
          DataBaseEventBus.instance.updateSafeSnapshot([snapshot.snapshotId]);
        }
        return value;
      });

  Future<List<SafeSnapshot>> snapshotItem(String assetId) =>
      (select(db.safeSnapshots)..where((tbl) => tbl.assetId.equals(assetId)))
          .get();
}
