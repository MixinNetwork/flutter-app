// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_conversation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemConversationMessage _$SystemConversationMessageFromJson(
    Map<String, dynamic> json) {
  return SystemConversationMessage(
    const MessageActionJsonConverter().fromJson(json['action'] as String),
    json['participant_id'] as String,
    json['user_id'] as String,
    _$enumDecodeNullable(_$ParticipantRoleEnumMap, json['role']),
  );
}

Map<String, dynamic> _$SystemConversationMessageToJson(
        SystemConversationMessage instance) =>
    <String, dynamic>{
      'action': const MessageActionJsonConverter().toJson(instance.action),
      'participant_id': instance.participantId,
      'user_id': instance.userId,
      'role': _$ParticipantRoleEnumMap[instance.role],
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$ParticipantRoleEnumMap = {
  ParticipantRole.owner: 'owner',
  ParticipantRole.admin: 'admin',
};
