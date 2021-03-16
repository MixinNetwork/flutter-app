// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_conversation_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemConversationMessage _$SystemConversationMessageFromJson(
    Map<String, dynamic> json) {
  return SystemConversationMessage(
    const MessageActionJsonConverter().fromJson(json['action'] as String?),
    json['participant_id'] as String?,
    json['user_id'] as String?,
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

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}

K? _$enumDecodeNullable<K, V>(
  Map<K, V> enumValues,
  dynamic source, {
  K? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<K, V>(enumValues, source, unknownValue: unknownValue);
}

const _$ParticipantRoleEnumMap = {
  ParticipantRole.owner: 'owner',
  ParticipantRole.admin: 'admin',
};
