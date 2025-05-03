// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_conversation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemConversationMessage _$SystemConversationMessageFromJson(
  Map<String, dynamic> json,
) => SystemConversationMessage(
  json['action'] as String?,
  json['participant_id'] as String?,
  json['user_id'] as String?,
  const ParticipantRoleJsonConverter().fromJson(json['role'] as String?),
  (json['expire_in'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SystemConversationMessageToJson(
  SystemConversationMessage instance,
) => <String, dynamic>{
  'action': instance.action,
  'participant_id': instance.participantId,
  'user_id': instance.userId,
  'role': const ParticipantRoleJsonConverter().toJson(instance.role),
  'expire_in': instance.expireIn,
};
