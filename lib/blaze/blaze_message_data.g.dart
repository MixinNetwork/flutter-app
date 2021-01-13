// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageData _$BlazeMessageDataFromJson(Map<String, dynamic> json) {
  return BlazeMessageData(
    json['conversation_id'] as String,
    json['user_id'] as String,
    json['message_id'] as String,
    json['category'] as String,
    json['data'] as String,
    json['status'] as String,
    json['created_at'] as String,
    json['updated_at'] as String,
    json['source'] as String,
    json['representative_id'] as String,
    json['quote_message_id'] as String,
    json['session_id'] as String,
  );
}

Map<String, dynamic> _$BlazeMessageDataToJson(BlazeMessageData instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'message_id': instance.messageId,
      'category': instance.category,
      'data': instance.data,
      'status': instance.status,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'source': instance.source,
      'representative_id': instance.representativeId,
      'quote_message_id': instance.quoteMessageId,
      'session_id': instance.sessionId,
    };
