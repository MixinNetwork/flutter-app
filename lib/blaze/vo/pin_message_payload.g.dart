// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_message_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinMessagePayload _$PinMessagePayloadFromJson(Map<String, dynamic> json) {
  return PinMessagePayload(
    action:
        _$enumDecodeNullable(_$PinMessagePayloadActionEnumMap, json['action']),
    messageIds:
        (json['message_ids'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$PinMessagePayloadToJson(PinMessagePayload instance) =>
    <String, dynamic>{
      'action': _$PinMessagePayloadActionEnumMap[instance.action],
      'message_ids': instance.messageIds,
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

const _$PinMessagePayloadActionEnumMap = {
  PinMessagePayloadAction.pin: 'PIN',
  PinMessagePayloadAction.unpin: 'UNPIN',
};
