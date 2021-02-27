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
      this.confirmations);

  factory SnapshotMessage.fromJson(Map<String, dynamic> json) =>
      _$SnapshotMessageFromJson(json);

  @JsonKey(name: 'snapshot_id', disallowNullValue: true)
  String snapshotId;
  @JsonKey(name: 'type', disallowNullValue: true)
  String type;
  @JsonKey(name: 'asset_id', disallowNullValue: true)
  String assetId;
  @JsonKey(name: 'amount', disallowNullValue: true)
  String amount;
  @JsonKey(name: 'created_at', disallowNullValue: true)
  String createdAt;
  @JsonKey(name: 'opponent_id')
  String opponentId;
  @JsonKey(name: 'trace_id')
  String traceId;
  @JsonKey(name: 'transaction_hash')
  String transactionHash;
  @JsonKey(name: 'sender')
  String sender;
  @JsonKey(name: 'receiver')
  String receiver;
  @JsonKey(name: 'memo')
  String memo;
  @JsonKey(name: 'confirmations')
  int confirmations;

  Map<String, dynamic> toJson() => _$SnapshotMessageToJson(this);
}
