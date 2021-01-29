// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_user_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemUserMessage _$SystemUserMessageFromJson(Map<String, dynamic> json) {
  return SystemUserMessage(
    _$enumDecode(_$SystemUserActionEnumMap, json['action']),
    json['user_id'] as String,
  );
}

Map<String, dynamic> _$SystemUserMessageToJson(SystemUserMessage instance) =>
    <String, dynamic>{
      'action': _$SystemUserActionEnumMap[instance.action],
      'user_id': instance.userId,
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

const _$SystemUserActionEnumMap = {
  SystemUserAction.update: 'UPDATE',
};
