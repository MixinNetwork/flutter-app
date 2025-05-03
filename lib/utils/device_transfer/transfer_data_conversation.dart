import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_conversation.g.dart';

@JsonSerializable()
@ConversationCategoryJsonConverter()
@ConversationStatusJsonConverter()
class TransferDataConversation {
  TransferDataConversation({
    required this.conversationId,
    required this.createdAt,
    required this.status,
    this.ownerId,
    this.category,
    this.name,
    this.announcement,
    this.codeUrl,
    this.payType,
    this.pinTime,
    this.lastMessageId,
    this.lastMessageCreatedAt,
    this.lastReadMessageId,
    this.unseenMessageCount,
    this.muteUntil,
    this.expireIn,
  });

  factory TransferDataConversation.fromDbConversation(db.Conversation c) =>
      TransferDataConversation(
        conversationId: c.conversationId,
        ownerId: c.ownerId,
        category: c.category,
        name: c.name,
        announcement: c.announcement,
        codeUrl: c.codeUrl,
        payType: c.payType,
        createdAt: c.createdAt,
        pinTime: c.pinTime,
        lastMessageId: c.lastMessageId,
        lastMessageCreatedAt: c.lastMessageCreatedAt,
        lastReadMessageId: c.lastReadMessageId,
        unseenMessageCount: c.unseenMessageCount,
        status: c.status,
        muteUntil: c.muteUntil,
        expireIn: c.expireIn,
      );

  factory TransferDataConversation.fromJson(Map<String, dynamic> json) =>
      _$TransferDataConversationFromJson(json);

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'owner_id')
  final String? ownerId;

  @JsonKey(name: 'category')
  final ConversationCategory? category;

  @JsonKey(name: 'name')
  final String? name;

  @JsonKey(name: 'announcement')
  final String? announcement;

  @JsonKey(name: 'code_url')
  final String? codeUrl;

  @JsonKey(name: 'pay_type')
  final String? payType;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'pin_time')
  final DateTime? pinTime;

  @JsonKey(name: 'last_message_id')
  final String? lastMessageId;

  @JsonKey(name: 'last_message_created_at')
  final DateTime? lastMessageCreatedAt;

  @JsonKey(name: 'last_read_message_id')
  final String? lastReadMessageId;

  @JsonKey(name: 'unseen_message_count')
  final int? unseenMessageCount;

  @JsonKey(name: 'status')
  final ConversationStatus status;

  @JsonKey(name: 'mute_until')
  final DateTime? muteUntil;

  @JsonKey(name: 'expire_in')
  final int? expireIn;

  Map<String, dynamic> toJson() => _$TransferDataConversationToJson(this);

  db.Conversation toDbConversation() => db.Conversation(
    conversationId: conversationId,
    ownerId: ownerId,
    category: category,
    name: name,
    announcement: announcement,
    codeUrl: codeUrl,
    payType: payType,
    createdAt: createdAt,
    pinTime: pinTime,
    lastMessageId: lastMessageId,
    lastMessageCreatedAt: lastMessageCreatedAt,
    lastReadMessageId: lastReadMessageId,
    unseenMessageCount: unseenMessageCount,
    status: status,
    muteUntil: muteUntil,
    expireIn: expireIn,
  );

  @override
  String toString() => 'TransferConversationData: $conversationId';
}
