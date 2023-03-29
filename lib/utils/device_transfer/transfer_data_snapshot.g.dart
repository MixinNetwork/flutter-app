// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataSnapshot _$TransferDataSnapshotFromJson(
        Map<String, dynamic> json) =>
    TransferDataSnapshot(
      snapshotId: json['snapshotId'] as String,
      type: json['type'] as String,
      assetId: json['assetId'] as String,
      amount: json['amount'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      opponentId: json['opponentId'] as String?,
      traceId: json['traceId'] as String?,
      transactionHash: json['transactionHash'] as String?,
      sender: json['sender'] as String?,
      receiver: json['receiver'] as String?,
      memo: json['memo'] as String?,
      confirmations: json['confirmations'] as int?,
    );

Map<String, dynamic> _$TransferDataSnapshotToJson(
        TransferDataSnapshot instance) =>
    <String, dynamic>{
      'snapshotId': instance.snapshotId,
      'traceId': instance.traceId,
      'type': instance.type,
      'assetId': instance.assetId,
      'amount': instance.amount,
      'createdAt': instance.createdAt.toIso8601String(),
      'opponentId': instance.opponentId,
      'transactionHash': instance.transactionHash,
      'sender': instance.sender,
      'receiver': instance.receiver,
      'memo': instance.memo,
      'confirmations': instance.confirmations,
    };
