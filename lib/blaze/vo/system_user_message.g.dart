// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_user_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemUserMessage _$SystemUserMessageFromJson(Map<String, dynamic> json) =>
    SystemUserMessage(
      $enumDecode(_$SystemUserActionEnumMap, json['action']),
      json['user_id'] as String,
    );

Map<String, dynamic> _$SystemUserMessageToJson(SystemUserMessage instance) =>
    <String, dynamic>{
      'action': _$SystemUserActionEnumMap[instance.action]!,
      'user_id': instance.userId,
    };

const _$SystemUserActionEnumMap = {SystemUserAction.update: 'UPDATE'};
