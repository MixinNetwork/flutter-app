// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_safe_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataSafeSnapshot _$TransferDataSafeSnapshotFromJson(
        Map<String, dynamic> json) =>
    TransferDataSafeSnapshot(
      snapshotId: json['snapshot_id'] as String,
      type: json['type'] as String,
      assetId: json['asset_id'] as String,
      amount: json['amount'] as String,
      userId: json['user_id'] as String,
      opponentId: json['opponent_id'] as String,
      memo: json['memo'] as String,
      transactionHash: json['transaction_hash'] as String,
      createdAt: json['created_at'] as String,
      traceId: json['trace_id'] as String?,
      confirmations: (json['confirmations'] as num?)?.toInt(),
      openingBalance: json['opening_balance'] as String?,
      closingBalance: json['closing_balance'] as String?,
      withdrawal: json['withdrawal'] == null
          ? null
          : SafeWithdrawal.fromJson(json['withdrawal'] as Map<String, dynamic>),
      deposit: json['deposit'] == null
          ? null
          : SafeDeposit.fromJson(json['deposit'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TransferDataSafeSnapshotToJson(
        TransferDataSafeSnapshot instance) =>
    <String, dynamic>{
      'snapshot_id': instance.snapshotId,
      'type': instance.type,
      'asset_id': instance.assetId,
      'amount': instance.amount,
      'user_id': instance.userId,
      'opponent_id': instance.opponentId,
      'memo': instance.memo,
      'transaction_hash': instance.transactionHash,
      'created_at': instance.createdAt,
      'trace_id': instance.traceId,
      'confirmations': instance.confirmations,
      'opening_balance': instance.openingBalance,
      'closing_balance': instance.closingBalance,
      'withdrawal': instance.withdrawal?.toJson(),
      'deposit': instance.deposit?.toJson(),
    };
