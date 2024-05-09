// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snapshot_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnapshotMessage _$SnapshotMessageFromJson(Map<String, dynamic> json) =>
    SnapshotMessage(
      json['snapshot_id'] as String,
      json['type'] as String,
      json['asset_id'] as String,
      json['amount'] as String,
      json['created_at'] as String,
      json['opponent_id'] as String?,
      json['trace_id'] as String?,
      json['transaction_hash'] as String?,
      json['sender'] as String?,
      json['receiver'] as String?,
      json['memo'] as String?,
      (json['confirmations'] as num?)?.toInt(),
      json['snapshot_hash'] as String?,
      json['opening_balance'] as String?,
      json['closing_balance'] as String?,
    );

Map<String, dynamic> _$SnapshotMessageToJson(SnapshotMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'snapshot_id': instance.snapshotId,
      'asset_id': instance.assetId,
      'amount': instance.amount,
      'created_at': instance.createdAt,
      'opponent_id': instance.opponentId,
      'trace_id': instance.traceId,
      'transaction_hash': instance.transactionHash,
      'sender': instance.sender,
      'receiver': instance.receiver,
      'memo': instance.memo,
      'confirmations': instance.confirmations,
      'snapshot_hash': instance.snapshotHash,
      'opening_balance': instance.openingBalance,
      'closing_balance': instance.closingBalance,
    };
