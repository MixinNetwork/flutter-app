// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_circle_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemCircleMessage _$SystemCircleMessageFromJson(Map<String, dynamic> json) =>
    SystemCircleMessage(
      $enumDecode(_$SystemCircleActionEnumMap, json['action']),
      json['circle_id'] as String,
      json['user_id'] as String?,
      json['conversation_id'] as String?,
    );

Map<String, dynamic> _$SystemCircleMessageToJson(
        SystemCircleMessage instance) =>
    <String, dynamic>{
      'action': _$SystemCircleActionEnumMap[instance.action]!,
      'circle_id': instance.circleId,
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
    };

const _$SystemCircleActionEnumMap = {
  SystemCircleAction.create: 'CREATE',
  SystemCircleAction.delete: 'DELETE',
  SystemCircleAction.update: 'UPDATE',
  SystemCircleAction.add: 'ADD',
  SystemCircleAction.remove: 'REMOVE',
};
