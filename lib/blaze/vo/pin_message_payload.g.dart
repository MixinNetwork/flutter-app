// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_message_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinMessagePayload _$PinMessagePayloadFromJson(Map<String, dynamic> json) =>
    PinMessagePayload(
      action: $enumDecodeNullable(
        _$PinMessagePayloadActionEnumMap,
        json['action'],
      ),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PinMessagePayloadToJson(PinMessagePayload instance) =>
    <String, dynamic>{
      'action': _$PinMessagePayloadActionEnumMap[instance.action],
      'message_ids': instance.messageIds,
    };

const _$PinMessagePayloadActionEnumMap = {
  PinMessagePayloadAction.pin: 'PIN',
  PinMessagePayloadAction.unpin: 'UNPIN',
};
