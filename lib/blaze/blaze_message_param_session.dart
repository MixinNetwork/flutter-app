import 'package:json_annotation/json_annotation.dart';

part 'blaze_message_param_session.g.dart';

@JsonSerializable()
class BlazeMessageParamSession {
  BlazeMessageParamSession({
    required this.userId,
    required this.sessionId,
  });

  factory BlazeMessageParamSession.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageParamSessionFromJson(json);

  @JsonKey(name: 'user_id')
  String userId;
  @JsonKey(name: 'session_id')
  String sessionId;

  Map<String, dynamic> toJson() => _$BlazeMessageParamSessionToJson(this);
}
