// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataConversation _$TransferDataConversationFromJson(
  Map<String, dynamic> json,
) => TransferDataConversation(
  conversationId: json['conversation_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  status: const ConversationStatusJsonConverter().fromJson(
    (json['status'] as num?)?.toInt(),
  ),
  ownerId: json['owner_id'] as String?,
  category: const ConversationCategoryJsonConverter().fromJson(
    json['category'] as String?,
  ),
  name: json['name'] as String?,
  announcement: json['announcement'] as String?,
  codeUrl: json['code_url'] as String?,
  payType: json['pay_type'] as String?,
  pinTime:
      json['pin_time'] == null
          ? null
          : DateTime.parse(json['pin_time'] as String),
  lastMessageId: json['last_message_id'] as String?,
  lastMessageCreatedAt:
      json['last_message_created_at'] == null
          ? null
          : DateTime.parse(json['last_message_created_at'] as String),
  lastReadMessageId: json['last_read_message_id'] as String?,
  unseenMessageCount: (json['unseen_message_count'] as num?)?.toInt(),
  muteUntil:
      json['mute_until'] == null
          ? null
          : DateTime.parse(json['mute_until'] as String),
  expireIn: (json['expire_in'] as num?)?.toInt(),
);

Map<String, dynamic> _$TransferDataConversationToJson(
  TransferDataConversation instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'owner_id': instance.ownerId,
  'category': const ConversationCategoryJsonConverter().toJson(
    instance.category,
  ),
  'name': instance.name,
  'announcement': instance.announcement,
  'code_url': instance.codeUrl,
  'pay_type': instance.payType,
  'created_at': instance.createdAt.toIso8601String(),
  'pin_time': instance.pinTime?.toIso8601String(),
  'last_message_id': instance.lastMessageId,
  'last_message_created_at': instance.lastMessageCreatedAt?.toIso8601String(),
  'last_read_message_id': instance.lastReadMessageId,
  'unseen_message_count': instance.unseenMessageCount,
  'status': const ConversationStatusJsonConverter().toJson(instance.status),
  'mute_until': instance.muteUntil?.toIso8601String(),
  'expire_in': instance.expireIn,
};
