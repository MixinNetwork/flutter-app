import 'package:flutter_app/enum/message_action.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

part 'system_conversation_message.g.dart';

@JsonSerializable()
@MessageActionJsonConverter()
class SystemConversationMessage {
  SystemConversationMessage(
      this.action, this.participantId, this.userId, this.role);

  factory SystemConversationMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemConversationMessageFromJson(json);

  @JsonKey(name: 'action')
  MessageAction action;
  @JsonKey(name: 'participant_id')
  String? participantId;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'role')
  ParticipantRole? role;

  Map<String, dynamic> toJson() => _$SystemConversationMessageToJson(this);
}
