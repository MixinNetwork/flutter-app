// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataSnapshot _$TransferDataSnapshotFromJson(
  Map<String, dynamic> json,
) => TransferDataSnapshot(
  snapshotId: json['snapshot_id'] as String,
  type: json['type'] as String,
  assetId: json['asset_id'] as String,
  amount: json['amount'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  opponentId: json['opponent_id'] as String?,
  traceId: json['trace_id'] as String?,
  transactionHash: json['transaction_hash'] as String?,
  sender: json['sender'] as String?,
  receiver: json['receiver'] as String?,
  memo: json['memo'] as String?,
  confirmations: (json['confirmations'] as num?)?.toInt(),
);

Map<String, dynamic> _$TransferDataSnapshotToJson(
  TransferDataSnapshot instance,
) => <String, dynamic>{
  'snapshot_id': instance.snapshotId,
  'trace_id': instance.traceId,
  'type': instance.type,
  'asset_id': instance.assetId,
  'amount': instance.amount,
  'created_at': instance.createdAt.toIso8601String(),
  'opponent_id': instance.opponentId,
  'transaction_hash': instance.transactionHash,
  'sender': instance.sender,
  'receiver': instance.receiver,
  'memo': instance.memo,
  'confirmations': instance.confirmations,
};
