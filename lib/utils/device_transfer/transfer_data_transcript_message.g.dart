// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_transcript_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataTranscriptMessage _$TransferDataTranscriptMessageFromJson(
        Map<String, dynamic> json) =>
    TransferDataTranscriptMessage(
      transcriptId: json['transcript_id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String?,
      userFullName: json['user_full_name'] as String?,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaName: json['media_name'] as String?,
      mediaSize: (json['media_size'] as num?)?.toInt(),
      mediaWidth: (json['media_width'] as num?)?.toInt(),
      mediaHeight: (json['media_height'] as num?)?.toInt(),
      mediaMimeType: json['media_mime_type'] as String?,
      mediaDuration: (json['media_duration'] as num?)?.toInt(),
      mediaStatus: const MediaStatusJsonConverter()
          .fromJson(json['media_status'] as String?),
      mediaWaveform: json['media_waveform'] as String?,
      thumbImage: json['thumb_image'] as String?,
      thumbUrl: json['thumb_url'] as String?,
      mediaKey: json['media_key'] as String?,
      mediaDigest: json['media_digest'] as String?,
      mediaCreatedAt:
          _safeDateTimeFromJson(json['media_created_at'] as String?),
      stickerId: json['sticker_id'] as String?,
      sharedUserId: json['shared_user_id'] as String?,
      mentions: json['mentions'] as String?,
      quoteId: json['quote_id'] as String?,
      quoteContent: json['quote_content'] as String?,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$TransferDataTranscriptMessageToJson(
        TransferDataTranscriptMessage instance) =>
    <String, dynamic>{
      'transcript_id': instance.transcriptId,
      'message_id': instance.messageId,
      'user_id': instance.userId,
      'user_full_name': instance.userFullName,
      'category': instance.category,
      'created_at': instance.createdAt.toIso8601String(),
      'content': instance.content,
      'media_url': instance.mediaUrl,
      'media_name': instance.mediaName,
      'media_size': instance.mediaSize,
      'media_width': instance.mediaWidth,
      'media_height': instance.mediaHeight,
      'media_mime_type': instance.mediaMimeType,
      'media_duration': instance.mediaDuration,
      'media_status':
          const MediaStatusJsonConverter().toJson(instance.mediaStatus),
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
