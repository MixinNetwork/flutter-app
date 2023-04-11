// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plain_json_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlainJsonMessage _$PlainJsonMessageFromJson(Map<String, dynamic> json) =>
    PlainJsonMessage(
      json['action'] as String,
      (json['messages'] as List<dynamic>?)?.map((e) => e as String).toList(),
      json['user_id'] as String?,
      json['message_id'] as String?,
      json['session_id'] as String?,
      (json['ack_messages'] as List<dynamic>?)
          ?.map((e) => BlazeAckMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      content: json['content'] as String?,
    );

Map<String, dynamic> _$PlainJsonMessageToJson(PlainJsonMessage instance) =>
    <String, dynamic>{
      'action': instance.action,
      'messages': instance.messages,
      'user_id': instance.userId,
      'message_id': instance.messageId,
      'session_id': instance.sessionId,
      'ack_messages': instance.ackMessages?.map((e) => e.toJson()).toList(),
      'content': instance.content,
    };
