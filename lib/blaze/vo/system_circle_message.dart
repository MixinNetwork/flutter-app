import 'package:flutter_app/enum/system_circle_action.dart';
import 'package:json_annotation/json_annotation.dart';
part 'system_circle_message.g.dart';
@JsonSerializable()
class SystemCircleMessage {
  SystemCircleMessage(
      this.action, this.circleId, this.userId, this.conversationId);

  factory SystemCircleMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemCircleMessageFromJson(json);

  @JsonKey(name: 'action', nullable: false)
  SystemCircleAction action;
  @JsonKey(name: 'circle_id', nullable: false)
  String circleId;
  @JsonKey(name: 'conversation_id')
  String conversationId;
  @JsonKey(name: 'user_id')
  String userId;

  Map<String, dynamic> toJson() => _$SystemCircleMessageToJson(this);
}
