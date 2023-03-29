import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_snapshot.g.dart';

@JsonSerializable()
class TransferDataSnapshot {
  TransferDataSnapshot({
    required this.snapshotId,
    required this.type,
    required this.assetId,
    required this.amount,
    required this.createdAt,
    this.opponentId,
    this.traceId,
    this.transactionHash,
    this.sender,
    this.receiver,
    this.memo,
    this.confirmations,
  });

  factory TransferDataSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TransferDataSnapshotFromJson(json);

  factory TransferDataSnapshot.fromDbSnapshot(db.Snapshot s) =>
      TransferDataSnapshot(
        snapshotId: s.snapshotId,
        type: s.type,
        assetId: s.assetId,
        amount: s.amount,
        createdAt: s.createdAt,
        opponentId: s.opponentId,
        traceId: s.traceId,
        transactionHash: s.transactionHash,
        sender: s.sender,
        receiver: s.receiver,
        memo: s.memo,
        confirmations: s.confirmations,
      );

  final String snapshotId;
  final String? traceId;
  final String type;
  final String assetId;
  final String amount;
  final DateTime createdAt;
  final String? opponentId;
  final String? transactionHash;
  final String? sender;
  final String? receiver;
  final String? memo;
  final int? confirmations;

  Map<String, dynamic> toJson() => _$TransferDataSnapshotToJson(this);

  db.Snapshot toDbSnapshot() => db.Snapshot(
        snapshotId: snapshotId,
        type: type,
        assetId: assetId,
        amount: amount,
        createdAt: createdAt,
        opponentId: opponentId,
        traceId: traceId,
        transactionHash: transactionHash,
        sender: sender,
        receiver: receiver,
        memo: memo,
        confirmations: confirmations,
      );

  @override
  String toString() => 'TransferDataSnapshot($snapshotId)';
}
