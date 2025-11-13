import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../../utils/extension/extension.dart';
import '../database_event_bus.dart';
import '../extension/db.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'snapshot_dao.g.dart';

extension SnapshotConverter on sdk.Snapshot {
  SnapshotsCompanion get asDbSnapshotObject => SnapshotsCompanion.insert(
    snapshotId: snapshotId,
    traceId: Value(traceId),
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

extension SnapshotItemExtension on SnapshotItem {
  String l10nType(BuildContext context) {
    if (type == sdk.SnapshotType.transfer) return context.l10n.transfer;
    if (type == sdk.SnapshotType.deposit) return context.l10n.deposit;
    if (type == sdk.SnapshotType.withdrawal) return context.l10n.withdrawal;
    if (type == sdk.SnapshotType.fee) return context.l10n.fee;
    if (type == sdk.SnapshotType.rebate) return context.l10n.rebate;
    if (type == sdk.SnapshotType.raw) return context.l10n.raw;
    return context.l10n.na;
  }
}

@DriftAccessor(include: {'../moor/dao/snapshot.drift'})
class SnapshotDao extends DatabaseAccessor<MixinDatabase>
    with _$SnapshotDaoMixin {
  SnapshotDao(super.db);

  Future<int> insert(Snapshot snapshot, {bool updateIfConflict = true}) =>
      into(
        db.snapshots,
      ).simpleInsert(snapshot, updateIfConflict: updateIfConflict).then((
        value,
      ) {
        DataBaseEventBus.instance.updateSnapshot([snapshot.snapshotId]);
        return value;
      });

  Future<int> insertSdkSnapshot(sdk.Snapshot snapshot) =>
      into(
        db.snapshots,
      ).insertOnConflictUpdate(snapshot.asDbSnapshotObject).then((value) {
        DataBaseEventBus.instance.updateSnapshot([snapshot.snapshotId]);
        return value;
      });

  Future deleteSnapshot(Snapshot snapshot) =>
      delete(db.snapshots).delete(snapshot).then((value) {
        DataBaseEventBus.instance.updateSnapshot([snapshot.snapshotId]);
        return value;
      });

  Selectable<SnapshotItem> snapshotItemById(
    String snapshotId,
    String currentFiat,
  ) => snapshotItems(
    currentFiat,
    (snapshot, opponent, asset, tempAsset, fiats) =>
        snapshot.snapshotId.equals(snapshotId),
    (snapshot, opponent, asset, tempAsset, fiats) => ignoreOrderBy,
    (snapshot, opponent, asset, tempAsset, fiats) => Limit(1, 0),
  );

  Selectable<String?> snapshotIdByTraceId(String traceId) =>
      (selectOnly(db.snapshots)
            ..addColumns([db.snapshots.snapshotId])
            ..where(db.snapshots.traceId.equals(traceId))
            ..limit(1))
          .map((row) => row.read(db.snapshots.snapshotId));

  Future<List<Snapshot>> getSnapshots({
    required int limit,
    required int offset,
  }) =>
      (select(db.snapshots)
            ..orderBy([(t) => OrderingTerm.asc(t.rowId)])
            ..limit(limit, offset: offset))
          .get();
}
