// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_signal_key_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeSignalKeyMessage _$BlazeSignalKeyMessageFromJson(
        Map<String, dynamic> json) =>
    BlazeSignalKeyMessage(
      json['message_id'] as String,
      json['recipient_id'] as String,
      json['data'] as String,
      json['session_id'] as String?,
    );

Map<String, dynamic> _$BlazeSignalKeyMessageToJson(
        BlazeSignalKeyMessage instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'recipient_id': instance.recipientId,
      'data': instance.data,
      'session_id': instance.sessionId,
    };
