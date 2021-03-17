// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageData _$BlazeMessageDataFromJson(Map<String, dynamic> json) {
  return BlazeMessageData(
    json['conversation_id'] as String?,
    json['user_id'] as String,
    json['message_id'] as String,
    const MessageCategoryJsonConverter().fromJson(json['category'] as String?),
    json['data'] as String,
    _$enumDecode(_$MessageStatusEnumMap, json['status']),
    DateTime.parse(json['created_at'] as String),
    DateTime.parse(json['updated_at'] as String),
    json['source'] as String,
    json['representative_id'] as String?,
    json['quote_message_id'] as String?,
    json['session_id'] as String,
  );
}

Map<String, dynamic> _$BlazeMessageDataToJson(BlazeMessageData instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'message_id': instance.messageId,
      'category':
          const MessageCategoryJsonConverter().toJson(instance.category),
      'data': instance.data,
      'status': _$MessageStatusEnumMap[instance.status],
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'source': instance.source,
      'representative_id': instance.representativeId,
      'quote_message_id': instance.quoteMessageId,
      'session_id': instance.sessionId,
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

const _$MessageStatusEnumMap = {
  MessageStatus.pending: 'PENDING',
  MessageStatus.sending: 'SENDING',
  MessageStatus.sent: 'SENT',
  MessageStatus.delivered: 'DELIVERED',
  MessageStatus.read: 'READ',
  MessageStatus.failed: 'FAILED',
  MessageStatus.unknown: 'UNKNOWN',
};
