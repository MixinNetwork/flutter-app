import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

part 'plain_json_message.g.dart';

@JsonSerializable()
class PlainJsonMessage {
  PlainJsonMessage(
    this.action,
    this.messages,
    this.userId,
    this.messageId,
    this.sessionId,
    this.ackMessages, {
    this.content,
  });

  factory PlainJsonMessage.create({
    required String action,
    List<String>? messages,
    String? userId,
    String? messageId,
    String? sessionId,
    List<BlazeAckMessage>? ackMessages,
    String? content,
  }) => PlainJsonMessage(
    action,
    messages,
    userId,
    messageId,
    sessionId,
    ackMessages,
    content: content,
  );

  factory PlainJsonMessage.fromJson(Map<String, dynamic> json) =>
      _$PlainJsonMessageFromJson(json);

  @JsonKey(name: 'action')
  String action;
  @JsonKey(name: 'messages')
  List<String>? messages;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'message_id')
  String? messageId;
  @JsonKey(name: 'session_id')
  String? sessionId;
  @JsonKey(name: 'ack_messages')
  List<BlazeAckMessage>? ackMessages;

  @JsonKey(name: 'content')
  String? content;

  Map<String, dynamic> toJson() => _$PlainJsonMessageToJson(this);
}
