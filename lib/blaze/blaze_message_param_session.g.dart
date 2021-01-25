// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_param_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageParamSession _$BlazeMessageParamSessionFromJson(
    Map<String, dynamic> json) {
  return BlazeMessageParamSession(
    userId: json['user_id'] as String,
    sessionId: json['session_id'] as String,
  );
}

Map<String, dynamic> _$BlazeMessageParamSessionToJson(
        BlazeMessageParamSession instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'session_id': instance.sessionId,
    };
