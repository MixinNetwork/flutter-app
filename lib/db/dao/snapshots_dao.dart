import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'snapshots_dao.g.dart';

@UseDao(tables: [Snapshots])
class SnapshotsDao extends DatabaseAccessor<MixinDatabase>
    with _$SnapshotsDaoMixin {
  SnapshotsDao(MixinDatabase db) : super(db);

  Future<int> insert(Snapshot snapshot) =>
      into(db.snapshots).insertOnConflictUpdate(snapshot);

  Future deleteSnapshot(Snapshot snapshot) =>
      delete(db.snapshots).delete(snapshot);
}
