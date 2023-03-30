import 'package:json_annotation/json_annotation.dart';

part 'snapshot_message.g.dart';

@JsonSerializable()
class SnapshotMessage {
  SnapshotMessage(
    this.snapshotId,
    this.type,
    this.assetId,
    this.amount,
    this.createdAt,
    this.opponentId,
    this.traceId,
    this.transactionHash,
    this.sender,
    this.receiver,
    this.memo,
    this.confirmations,
    this.snapshotHash,
    this.openingBalance,
    this.closingBalance,
  );

  factory SnapshotMessage.fromJson(Map<String, dynamic> json) =>
      _$SnapshotMessageFromJson(json);

  @JsonKey(name: 'type')
  String type;
  @JsonKey(name: 'snapshot_id')
  String snapshotId;
  @JsonKey(name: 'asset_id')
  String assetId;
  @JsonKey(name: 'amount')
  String amount;
  @JsonKey(name: 'created_at')
  String createdAt;
  @JsonKey(name: 'opponent_id')
  String? opponentId;
  @JsonKey(name: 'trace_id')
  String? traceId;
  @JsonKey(name: 'transaction_hash')
  String? transactionHash;
  @JsonKey(name: 'sender')
  String? sender;
  @JsonKey(name: 'receiver')
  String? receiver;
  @JsonKey(name: 'memo')
  String? memo;
  @JsonKey(name: 'confirmations')
  int? confirmations;
  @JsonKey(name: 'snapshot_hash')
  String? snapshotHash;
  @JsonKey(name: 'opening_balance')
  String? openingBalance;
  @JsonKey(name: 'closing_balance')
  String? closingBalance;

  Map<String, dynamic> toJson() => _$SnapshotMessageToJson(this);
}
