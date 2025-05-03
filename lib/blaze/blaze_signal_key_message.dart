import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'blaze_signal_key_message.g.dart';

@JsonSerializable()
class BlazeSignalKeyMessage {
  BlazeSignalKeyMessage(
    this.messageId,
    this.recipientId,
    this.data,
    this.sessionId,
  );

  factory BlazeSignalKeyMessage.fromJson(Map<String, dynamic> json) =>
      _$BlazeSignalKeyMessageFromJson(json);

  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'recipient_id')
  final String recipientId;
  @JsonKey(name: 'data')
  final String data;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  Map<String, dynamic> toJson() => _$BlazeSignalKeyMessageToJson(this);
}

BlazeSignalKeyMessage createBlazeSignalKeyMessage(
  String recipientId,
  String data, {
  String? sessionId,
}) => BlazeSignalKeyMessage(const Uuid().v4(), recipientId, data, sessionId);
