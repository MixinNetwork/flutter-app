// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_session_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemSessionMessage _$SystemSessionMessageFromJson(
  Map<String, dynamic> json,
) => SystemSessionMessage(
  $enumDecode(_$SystemUserActionEnumMap, json['action']),
  json['user_id'] as String,
)..sessionId = json['session_id'] as String?;

Map<String, dynamic> _$SystemSessionMessageToJson(
  SystemSessionMessage instance,
) => <String, dynamic>{
  'action': _$SystemUserActionEnumMap[instance.action]!,
  'user_id': instance.userId,
  'session_id': instance.sessionId,
};

const _$SystemUserActionEnumMap = {SystemUserAction.update: 'UPDATE'};
