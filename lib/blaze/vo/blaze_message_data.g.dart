// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageData _$BlazeMessageDataFromJson(Map<String, dynamic> json) =>
    BlazeMessageData(
      json['conversation_id'] as String,
      json['user_id'] as String,
      json['message_id'] as String,
      json['category'] as String?,
      json['data'] as String,
      $enumDecode(_$MessageStatusEnumMap, json['status']),
      DateTime.parse(json['created_at'] as String),
      DateTime.parse(json['updated_at'] as String),
      json['source'] as String,
      json['representative_id'] as String?,
      json['quote_message_id'] as String?,
      json['session_id'] as String,
    )..silent = json['silent'] as bool?;

Map<String, dynamic> _$BlazeMessageDataToJson(BlazeMessageData instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'message_id': instance.messageId,
      'category': instance.category,
      'data': instance.data,
      'status': _$MessageStatusEnumMap[instance.status],
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'source': instance.source,
      'representative_id': instance.representativeId,
      'quote_message_id': instance.quoteMessageId,
      'session_id': instance.sessionId,
      'silent': instance.silent,
    };

const _$MessageStatusEnumMap = {
  MessageStatus.failed: 'FAILED',
  MessageStatus.unknown: 'UNKNOWN',
  MessageStatus.sending: 'SENDING',
  MessageStatus.sent: 'SENT',
  MessageStatus.delivered: 'DELIVERED',
  MessageStatus.read: 'READ',
};
