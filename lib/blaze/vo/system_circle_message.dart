import 'package:json_annotation/json_annotation.dart';

import '../../enum/system_circle_action.dart';

part 'system_circle_message.g.dart';

@JsonSerializable()
class SystemCircleMessage {
  SystemCircleMessage(
    this.action,
    this.circleId,
    this.userId,
    this.conversationId,
  );

  factory SystemCircleMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemCircleMessageFromJson(json);

  @JsonKey(name: 'action')
  SystemCircleAction action;
  @JsonKey(name: 'circle_id')
  String circleId;
  @JsonKey(name: 'conversation_id')
  String? conversationId;
  @JsonKey(name: 'user_id')
  String? userId;

  Map<String, dynamic> toJson() => _$SystemCircleMessageToJson(this);
}
