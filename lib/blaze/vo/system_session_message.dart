import 'package:json_annotation/json_annotation.dart';

import '../../enum/system_user_action.dart';

part 'system_session_message.g.dart';

@JsonSerializable()
class SystemSessionMessage {
  SystemSessionMessage(this.action, this.userId);

  factory SystemSessionMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemSessionMessageFromJson(json);

  @JsonKey(name: 'action')
  SystemUserAction action;
  @JsonKey(name: 'user_id')
  String userId;
  @JsonKey(name: 'session_id')
  String? sessionId;

  Map<String, dynamic> toJson() => _$SystemSessionMessageToJson(this);
}
