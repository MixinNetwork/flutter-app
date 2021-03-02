import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:json_annotation/json_annotation.dart';

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

  @JsonKey(name: 'conversation_id', disallowNullValue: true)
  String? conversationId;
  @JsonKey(name: 'user_id', disallowNullValue: true)
  String userId;
  @JsonKey(name: 'message_id', disallowNullValue: true)
  String messageId;
  @JsonKey(name: 'category')
  MessageCategory category;
  @JsonKey(name: 'data', disallowNullValue: true)
  String data;
  @JsonKey(name: 'status', disallowNullValue: true)
  MessageStatus status;
  @JsonKey(name: 'created_at', disallowNullValue: true)
  DateTime createdAt;
  @JsonKey(name: 'updated_at', disallowNullValue: true)
  DateTime updatedAt;
  @JsonKey(name: 'source', disallowNullValue: true)
  String source;
  @JsonKey(name: 'representative_id')
  String representativeId;
  @JsonKey(name: 'quote_message_id')
  String? quoteMessageId;
  @JsonKey(name: 'session_id')
  String sessionId;

  Map<String, dynamic> toJson() => _$BlazeMessageDataToJson(this);
}
