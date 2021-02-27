import 'package:flutter_app/enum/system_user_action.dart';
import 'package:json_annotation/json_annotation.dart';

part 'system_session_message.g.dart';

@JsonSerializable()
class SystemSessionMessage {
  SystemSessionMessage(this.action, this.userId);

  factory SystemSessionMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemSessionMessageFromJson(json);

  @JsonKey(name: 'action', disallowNullValue: true)
  SystemUserAction action;
  @JsonKey(name: 'user_id', disallowNullValue: true)
  String userId;
  @JsonKey(name: 'session_id', disallowNullValue: true)
  String? sessionId;

  Map<String, dynamic> toJson() => _$SystemSessionMessageToJson(this);
}
