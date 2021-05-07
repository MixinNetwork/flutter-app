import 'package:json_annotation/json_annotation.dart';

import '../../enum/system_user_action.dart';

part 'system_user_message.g.dart';

@JsonSerializable()
class SystemUserMessage {
  SystemUserMessage(this.action, this.userId);

  factory SystemUserMessage.fromJson(Map<String, dynamic> json) =>
      _$SystemUserMessageFromJson(json);

  @JsonKey(name: 'action')
  SystemUserAction action;
  @JsonKey(name: 'user_id')
  String userId;

  Map<String, dynamic> toJson() => _$SystemUserMessageToJson(this);
}
