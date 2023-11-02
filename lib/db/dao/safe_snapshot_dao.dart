import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';

part 'safe_snapshot_dao.g.dart';

extension _SafeSnapshotConverter on sdk.SafeSnapshot {
  SafeSnapshotsCompanion get asDbSafeSnapshotObject =>
      SafeSnapshotsCompanion.insert(
        snapshotId: snapshotId,
        type: type,
        assetId: assetId,
        amount: amount,
        userId: userId,
        opponentId: opponentId,
        memo: memo,
        transactionHash: transactionHash,
        createdAt: createdAt,
        traceId: Value(traceId),
        confirmations: Value(confirmations),
        openingBalance: Value(openingBalance),
        closingBalance: Value(closingBalance),
      );
}

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

  Selectable<SafeSnapshot> safeSnapshotById(String snapshotId) =>
      select(safeSnapshots)..where((tbl) => tbl.snapshotId.equals(snapshotId));

  Future<int> insertSdkSnapshot(sdk.SafeSnapshot data) => into(safeSnapshots)
          .insertOnConflictUpdate(data.asDbSafeSnapshotObject)
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateSafeSnapshot([data.snapshotId]);
        }
        return value;
      });
}
