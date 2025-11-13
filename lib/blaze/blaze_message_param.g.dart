// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blaze_message_param.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BlazeMessageParam _$BlazeMessageParamFromJson(Map<String, dynamic> json) =>
    BlazeMessageParam(
      conversationId: json['conversation_id'] as String?,
      recipientId: json['recipient_id'] as String?,
      messageId: json['message_id'] as String?,
      category: json['category'] as String?,
      data: json['data'] as String?,
      status: json['status'] as String?,
      recipients: (json['recipients'] as List<dynamic>?)
          ?.map(
            (e) => BlazeMessageParamSession.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      keys: json['keys'] == null
          ? null
          : SignalKeyRequest.fromJson(json['keys'] as Map<String, dynamic>),
      messages: json['messages'] as List<dynamic>?,
      quoteMessageId: json['quote_message_id'] as String?,
      sessionId: json['session_id'] as String?,
      representativeId: json['representative_id'] as String?,
      conversationChecksum: json['conversation_checksum'] as String?,
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      jsep: json['jsep'] as String?,
      candidate: json['candidate'] as String?,
      trackId: json['track_id'] as String?,
      recipientIds: (json['recipient_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      silent: json['silent'] as bool?,
      expireIn: (json['expire_in'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BlazeMessageParamToJson(BlazeMessageParam instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'recipient_id': instance.recipientId,
      'message_id': instance.messageId,
      'category': instance.category,
      'data': instance.data,
      'status': instance.status,
      'recipients': instance.recipients?.map((e) => e.toJson()).toList(),
      'keys': instance.keys?.toJson(),
      'messages': instance.messages,
      'quote_message_id': instance.quoteMessageId,
      'session_id': instance.sessionId,
      'representative_id': instance.representativeId,
      'conversation_checksum': instance.conversationChecksum,
      'mentions': instance.mentions,
      'jsep': instance.jsep,
      'candidate': instance.candidate,
      'track_id': instance.trackId,
      'recipient_ids': instance.recipientIds,
      'silent': instance.silent,
      'expire_in': instance.expireIn,
    };
