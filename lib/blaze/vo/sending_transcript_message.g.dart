// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sending_transcript_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendingTranscriptMessage _$SendingTranscriptMessageFromJson(
        Map<String, dynamic> json) =>
    SendingTranscriptMessage(
      transcriptId: json['transcript_id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String?,
      userFullName: json['user_full_name'] as String?,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String?,
      mediaName: json['media_name'] as String?,
      mediaSize: json['media_size'] as int?,
      mediaWidth: json['media_width'] as int?,
      mediaHeight: json['media_height'] as int?,
      mediaMimeType: json['media_mime_type'] as String?,
      mediaDuration: json['media_duration'] as String?,
      mediaWaveform: json['media_waveform'] as String?,
      thumbImage: json['thumb_image'] as String?,
      thumbUrl: json['thumb_url'] as String?,
      mediaKey: json['media_key'] as String?,
      mediaDigest: json['media_digest'] as String?,
      mediaCreatedAt: json['media_created_at'] == null
          ? null
          : DateTime.parse(json['media_created_at'] as String),
      stickerId: json['sticker_id'] as String?,
      sharedUserId: json['shared_user_id'] as String?,
      mentions: json['mentions'] as String?,
      quoteId: json['quote_id'] as String?,
      quoteContent: json['quote_content'] as String?,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$SendingTranscriptMessageToJson(
        SendingTranscriptMessage instance) =>
    <String, dynamic>{
      'transcript_id': instance.transcriptId,
      'message_id': instance.messageId,
      'user_id': instance.userId,
      'user_full_name': instance.userFullName,
      'category': instance.category,
      'created_at': instance.createdAt.toIso8601String(),
      'content': instance.content,
      'media_name': instance.mediaName,
      'media_size': instance.mediaSize,
      'media_width': instance.mediaWidth,
      'media_height': instance.mediaHeight,
      'media_mime_type': instance.mediaMimeType,
      'media_duration': instance.mediaDuration,
      'media_waveform': instance.mediaWaveform,
      'thumb_image': instance.thumbImage,
      'thumb_url': instance.thumbUrl,
      'media_key': instance.mediaKey,
      'media_digest': instance.mediaDigest,
      'media_created_at': instance.mediaCreatedAt?.toIso8601String(),
      'sticker_id': instance.stickerId,
      'shared_user_id': instance.sharedUserId,
      'mentions': instance.mentions,
      'quote_id': instance.quoteId,
      'quote_content': instance.quoteContent,
      'caption': instance.caption,
    };
