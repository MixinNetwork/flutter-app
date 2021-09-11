// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinMessage _$PinMessageFromJson(Map<String, dynamic> json) {
  return PinMessage(
    action: json['action'] as String,
    messageIds:
        (json['message_ids'] as List<dynamic>).map((e) => e as String).toList(),
  );
}

Map<String, dynamic> _$PinMessageToJson(PinMessage instance) =>
    <String, dynamic>{
      'action': instance.action,
      'message_ids': instance.messageIds,
    };
