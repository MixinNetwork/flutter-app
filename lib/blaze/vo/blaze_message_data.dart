import 'package:json_annotation/json_annotation.dart';

import '../../enum/message_category.dart';
import '../../enum/message_status.dart';

part 'blaze_message_data.g.dart';

@JsonSerializable()
@MessageCategoryJsonConverter()
class BlazeMessageData {
  BlazeMessageData(
    this.conversationId,
    this.userId,
    this.messageId,
    this.category,
    this.data,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.source,
    this.representativeId,
    this.quoteMessageId,
    this.sessionId,
  );

  factory BlazeMessageData.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageDataFromJson(json);

  @JsonKey(name: 'conversation_id')
  String conversationId;
  @JsonKey(name: 'user_id')
  String userId;
  @JsonKey(name: 'message_id')
  String messageId;
  @JsonKey(name: 'category')
  MessageCategory? category;
  @JsonKey(name: 'data')
  String data;
  @JsonKey(name: 'status')
  MessageStatus status;
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;
  @JsonKey(name: 'source')
  String source;
  @JsonKey(name: 'representative_id')
  String? representativeId;
  @JsonKey(name: 'quote_message_id')
  String? quoteMessageId;
  @JsonKey(name: 'session_id')
  String sessionId;

  Map<String, dynamic> toJson() => _$BlazeMessageDataToJson(this);

  String get senderId =>
      (representativeId?.isNotEmpty ?? false) ? representativeId! : userId;
}
