import 'package:json_annotation/json_annotation.dart';

part 'blaze_message_data.g.dart';

@JsonSerializable()
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
      this.sessionId);

  factory BlazeMessageData.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageDataFromJson(json);

  @JsonKey(name: 'conversation_id', nullable: false)
  String conversationId;
  @JsonKey(name: 'user_id', nullable: false)
  String userId;
  @JsonKey(name: 'message_id', nullable: false)
  String messageId;
  @JsonKey(name: 'category', nullable: false)
  String category;
  @JsonKey(name: 'data', nullable: false)
  String data;
  @JsonKey(name: 'status', nullable: false)
  String status;
  @JsonKey(name: 'created_at', nullable: false)
  DateTime createdAt;
  @JsonKey(name: 'updated_at', nullable: false)
  DateTime updatedAt;
  @JsonKey(name: 'source', nullable: false)
  String source;
  @JsonKey(name: 'representative_id')
  String representativeId;
  @JsonKey(name: 'quote_message_id')
  String quoteMessageId;
  @JsonKey(name: 'session_id')
  String sessionId;

  Map<String, dynamic> toJson() => _$BlazeMessageDataToJson(this);
}
