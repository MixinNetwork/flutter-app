// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageData _$BlazeMessageDataFromJson(Map<String, dynamic> json) {
  $checkKeys(json, disallowNullValues: const [
    'conversation_id',
    'user_id',
    'message_id',
    'data',
    'status',
    'created_at',
    'updated_at',
    'source'
  ]);
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

Map<String, dynamic> _$BlazeMessageDataToJson(BlazeMessageData instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('conversation_id', instance.conversationId);
  val['user_id'] = instance.userId;
  val['message_id'] = instance.messageId;
  val['category'] =
      const MessageCategoryJsonConverter().toJson(instance.category);
  val['data'] = instance.data;
  val['status'] = _$MessageStatusEnumMap[instance.status];
  val['created_at'] = instance.createdAt.toIso8601String();
  val['updated_at'] = instance.updatedAt.toIso8601String();
  val['source'] = instance.source;
  val['representative_id'] = instance.representativeId;
  val['quote_message_id'] = instance.quoteMessageId;
  val['session_id'] = instance.sessionId;
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

const _$MessageStatusEnumMap = {
  MessageStatus.pending: 'PENDING',
  MessageStatus.sending: 'SENDING',
  MessageStatus.sent: 'SENT',
  MessageStatus.delivered: 'DELIVERED',
  MessageStatus.read: 'READ',
  MessageStatus.failed: 'FAILED',
  MessageStatus.unknown: 'UNKNOWN',
};
