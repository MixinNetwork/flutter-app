import 'package:json_annotation/json_annotation.dart';

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

  @override
  String toString() => 'TransferDataSnapshot($snapshotId)';
}
