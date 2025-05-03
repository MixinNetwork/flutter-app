import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import '../crypto/signal/signal_key_request.dart';
import 'blaze_message_param_session.dart';
import 'blaze_signal_key_message.dart';

part 'blaze_message_param.g.dart';

@JsonSerializable()
class BlazeMessageParam {
  BlazeMessageParam({
    this.conversationId,
    this.recipientId,
    this.messageId,
    this.category,
    this.data,
    this.status,
    this.recipients,
    this.keys,
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
    this.silent,
    this.expireIn = 0,
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
  String? category;
  @JsonKey(name: 'data')
  String? data;
  @JsonKey(name: 'status')
  String? status;
  @JsonKey(name: 'recipients')
  List<BlazeMessageParamSession>? recipients;
  @JsonKey(name: 'keys')
  SignalKeyRequest? keys;
  @JsonKey(name: 'messages')
  List<dynamic>? messages;
  @JsonKey(name: 'quote_message_id')
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
  @JsonKey(name: 'silent')
  bool? silent;
  @JsonKey(name: 'expire_in')
  int expireIn;

  Map<String, dynamic> toJson() => _$BlazeMessageParamToJson(this);
}

BlazeMessageParam createSignalKeyMessageParam(
  String conversationId,
  List<BlazeSignalKeyMessage> messages,
  String conversationChecksum,
) => BlazeMessageParam(
  conversationId: conversationId,
  messages: messages,
  conversationChecksum: conversationChecksum,
);
