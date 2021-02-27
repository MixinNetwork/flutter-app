// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_session_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemSessionMessage _$SystemSessionMessageFromJson(Map<String, dynamic> json) {
  $checkKeys(json,
      disallowNullValues: const ['action', 'user_id', 'session_id']);
  return SystemSessionMessage(
    _$enumDecode(_$SystemUserActionEnumMap, json['action']),
    json['user_id'] as String,
  )..sessionId = json['session_id'] as String?;
}

Map<String, dynamic> _$SystemSessionMessageToJson(
    SystemSessionMessage instance) {
  final val = <String, dynamic>{
    'action': _$SystemUserActionEnumMap[instance.action],
    'user_id': instance.userId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('session_id', instance.sessionId);
  return val;
}

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

const _$SystemUserActionEnumMap = {
  SystemUserAction.update: 'UPDATE',
};
