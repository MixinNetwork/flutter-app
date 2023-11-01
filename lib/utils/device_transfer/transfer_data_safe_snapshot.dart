import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_safe_snapshot.g.dart';

@JsonSerializable()
class TransferDataSafeSnapshot {
  TransferDataSafeSnapshot({
    required this.snapshotId,
    required this.type,
    required this.assetId,
    required this.amount,
    required this.userId,
    required this.opponentId,
    required this.memo,
    required this.transactionHash,
    required this.createdAt,
    required this.traceId,
    required this.confirmations,
    required this.openingBalance,
    required this.closingBalance,
  });

  factory TransferDataSafeSnapshot.fromJson(Map<String, dynamic> json) =>
      _$TransferDataSafeSnapshotFromJson(json);

  @JsonKey(name: 'snapshot_id')
  final String snapshotId;
  @JsonKey(name: 'type')
  final String type;
  @JsonKey(name: 'asset_id')
  final String assetId;
  @JsonKey(name: 'amount')
  final String amount;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'opponent_id')
  final String opponentId;
  @JsonKey(name: 'memo')
  final String memo;
  @JsonKey(name: 'transaction_hash')
  final String transactionHash;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'trace_id')
  final String? traceId;
  @JsonKey(name: 'confirmations')
  final int? confirmations;
  @JsonKey(name: 'opening_balance')
  final String? openingBalance;
  @JsonKey(name: 'closing_balance')
  final String? closingBalance;

  Map<String, dynamic> toJson() => _$TransferDataSafeSnapshotToJson(this);

  db.SafeSnapshot toDbSafeSnapshot() => db.SafeSnapshot(
        snapshotId: snapshotId,
        type: type,
        assetId: assetId,
        amount: amount,
        userId: userId,
        opponentId: opponentId,
        memo: memo,
        transactionHash: transactionHash,
        createdAt: createdAt,
        traceId: traceId,
        confirmations: confirmations,
        openingBalance: openingBalance,
        closingBalance: closingBalance,
      );
}
