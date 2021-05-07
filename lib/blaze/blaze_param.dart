import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import '../enum/message_category.dart';
import 'blaze_message_param_session.dart';

part 'blaze_param.g.dart';

@JsonSerializable()
@MessageCategoryJsonConverter()
class BlazeMessageParam {
  BlazeMessageParam({
    this.conversationId,
    this.recipientId,
    this.messageId,
    this.category,
    this.data,
    this.status,
    this.recipients,
    this.messages,
    this.quoteMessageId,
    this.sessionId,
    this.representativeId,
    this.conversationChecksum,
    this.mentions,
    this.jsep,
    this.candidate,
    this.trackId,
    this.recipientIds,
  });

  factory BlazeMessageParam.fromJson(Map<String, dynamic> json) =>
      _$BlazeMessageParamFromJson(json);

  @JsonKey(name: 'conversation_id')
  String? conversationId;
  @JsonKey(name: 'recipient_id')
  String? recipientId;
  @JsonKey(name: 'message_id')
  String? messageId;
  @JsonKey(name: 'category')
  MessageCategory? category;
  @JsonKey(name: 'data')
  String? data;
  @JsonKey(name: 'status')
  String? status;
  @JsonKey(name: 'recipients')
  List<BlazeMessageParamSession>? recipients;

  // todo
  // @JsonKey(name: 'conversation_id')
  // SignalKeyRequest keys;
  @JsonKey(name: 'messages')
  List<dynamic>? messages;
  @JsonKey(name: 'quoteMessage_id')
  String? quoteMessageId;
  @JsonKey(name: 'session_id')
  String? sessionId;
  @JsonKey(name: 'representative_id')
  String? representativeId;
  @JsonKey(name: 'conversation_checksum')
  String? conversationChecksum;
  @JsonKey(name: 'mentions')
  List<String>? mentions;
  @JsonKey(name: 'jsep')
  String? jsep;
  @JsonKey(name: 'candidate')
  String? candidate;
  @JsonKey(name: 'track_id')
  String? trackId;
  @JsonKey(name: 'recipient_ids')
  List<String>? recipientIds;

  Map<String, dynamic> toJson() => _$BlazeMessageParamToJson(this);
}
