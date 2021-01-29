import 'package:flutter_app/enum/system_conversation_action.dart';
import 'package:json_annotation/json_annotation.dart';

part 'system_conversation_message.g.dart';

@JsonSerializable()
class SystemConversationMessage {
  SystemConversationMessage(
      this.action, this.participantId, this.userId, this.role);

  factory SystemConversationMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemConversationMessageFromJson(json);

  @JsonKey(name: 'action', nullable: false)
  SystemConversationAction action;
  @JsonKey(name: 'participant_id')
  String participantId;
  @JsonKey(name: 'user_id')
  String userId;
  @JsonKey(name: 'role')
  String role;

  Map<String, dynamic> toJson() => _$SystemConversationMessageToJson(this);
}
