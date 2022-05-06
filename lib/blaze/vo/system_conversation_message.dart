import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

part 'system_conversation_message.g.dart';

@JsonSerializable()
@ParticipantRoleJsonConverter()
class SystemConversationMessage {
  SystemConversationMessage(
    this.action,
    this.participantId,
    this.userId,
    this.role,
    this.expireIn,
  );

  factory SystemConversationMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemConversationMessageFromJson(json);

  @JsonKey(name: 'action')
  String? action;
  @JsonKey(name: 'participant_id')
  String? participantId;
  @JsonKey(name: 'user_id')
  String? userId;
  @JsonKey(name: 'role')
  ParticipantRole? role;
  @JsonKey(name: 'expire_in', defaultValue: 0)
  int expireIn;

  Map<String, dynamic> toJson() => _$SystemConversationMessageToJson(this);
}
