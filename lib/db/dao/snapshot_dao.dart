import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../mixin_database.dart';
import '../util/util.dart';

part 'snapshot_dao.g.dart';

extension SnapshotConverter on sdk.Snapshot {
  SnapshotsCompanion get asDbSnapshotObject => SnapshotsCompanion.insert(
        snapshotId: snapshotId,
        type: type,
        assetId: assetId,
        amount: amount,
        createdAt: createdAt,
        opponentId: Value(opponentId),
        transactionHash: Value(transactionHash),
        sender: Value(sender),
        receiver: Value(receiver),
        memo: Value(memo),
        confirmations: Value(confirmations),
      );
}

@DriftAccessor(tables: [Snapshots], include: {'../moor/dao/snapshot.drift'})
class SnapshotDao extends DatabaseAccessor<MixinDatabase>
    with _$SnapshotDaoMixin {
  SnapshotDao(MixinDatabase db) : super(db);

  Future<int> insert(Snapshot snapshot) =>
      into(db.snapshots).insertOnConflictUpdate(snapshot);

  Future<int> insertSdkSnapshot(sdk.Snapshot snapshot) =>
      into(db.snapshots).insertOnConflictUpdate(snapshot.asDbSnapshotObject);

  Future deleteSnapshot(Snapshot snapshot) =>
      delete(db.snapshots).delete(snapshot);

  Selectable<SnapshotItem> snapshotById(
          String snapshotId, String currentFiat) =>
      snapshotItems(
        currentFiat,
        (snapshot, opponent, asset, tempAsset, fiats) =>
            snapshot.snapshotId.equals(snapshotId),
        (snapshot, opponent, asset, tempAsset, fiats) => ignoreOrderBy,
        (snapshot, opponent, asset, tempAsset, fiats) => Limit(1, 0),
      );
}
