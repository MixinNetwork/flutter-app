// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_param_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageParamSession _$BlazeMessageParamSessionFromJson(
  Map<String, dynamic> json,
) => BlazeMessageParamSession(
  userId: json['user_id'] as String,
  sessionId: json['session_id'] as String,
);

Map<String, dynamic> _$BlazeMessageParamSessionToJson(
  BlazeMessageParamSession instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'session_id': instance.sessionId,
};

BlazeMessageParamOffset _$BlazeMessageParamOffsetFromJson(
  Map<String, dynamic> json,
) => BlazeMessageParamOffset(offset: json['offset'] as String?);

Map<String, dynamic> _$BlazeMessageParamOffsetToJson(
  BlazeMessageParamOffset instance,
) => <String, dynamic>{'offset': instance.offset};
