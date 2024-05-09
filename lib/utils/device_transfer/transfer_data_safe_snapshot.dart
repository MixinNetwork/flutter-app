import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

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
    this.withdrawal,
    this.deposit,
    this.inscriptionHash,
  });

  factory TransferDataSafeSnapshot.fromDbSnapshot(db.SafeSnapshot snapshot) =>
      TransferDataSafeSnapshot(
        snapshotId: snapshot.snapshotId,
        type: snapshot.type,
        assetId: snapshot.assetId,
        amount: snapshot.amount,
        userId: snapshot.userId,
        opponentId: snapshot.opponentId,
        memo: snapshot.memo,
        transactionHash: snapshot.transactionHash,
        createdAt: snapshot.createdAt,
        traceId: snapshot.traceId,
        confirmations: snapshot.confirmations,
        openingBalance: snapshot.openingBalance,
        closingBalance: snapshot.closingBalance,
        withdrawal: snapshot.withdrawal,
        deposit: snapshot.deposit,
        inscriptionHash: snapshot.inscriptionHash,
      );

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
  @JsonKey(name: 'withdrawal')
  final SafeWithdrawal? withdrawal;
  @JsonKey(name: 'deposit')
  final SafeDeposit? deposit;
  @JsonKey(name: 'inscription_hash')
  final String? inscriptionHash;

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
        withdrawal: withdrawal,
        deposit: deposit,
        inscriptionHash: inscriptionHash,
      );
}
