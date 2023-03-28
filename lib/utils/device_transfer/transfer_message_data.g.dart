// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_message_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferMessageData _$TransferMessageDataFromJson(Map<String, dynamic> json) =>
    TransferMessageData(
      messageId: json['message_id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: $enumDecode(_$MessageStatusEnumMap, json['status']),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaMimeType: json['media_mime_type'] as String?,
      mediaSize: json['media_size'] as int?,
      mediaDuration: json['media_duration'] as String?,
      mediaWidth: json['media_width'] as int?,
      mediaHeight: json['media_height'] as int?,
      mediaHash: json['media_hash'] as String?,
      thumbImage: json['thumb_image'] as String?,
      mediaKey: json['media_key'] as String?,
      mediaDigest: json['media_digest'] as String?,
      mediaStatus:
          $enumDecodeNullable(_$MediaStatusEnumMap, json['media_status']),
      action: json['action'] as String?,
      participantId: json['participant_id'] as String?,
      snapshotId: json['snapshot_id'] as String?,
      hyperlink: json['hyperlink'] as String?,
      name: json['name'] as String?,
      albumId: json['album_id'] as String?,
      stickerId: json['sticker_id'] as String?,
      sharedUserId: json['shared_user_id'] as String?,
      mediaWaveform: json['media_waveform'] as String?,
      quoteMessageId: json['quote_message_id'] as String?,
      quoteContent: json['quote_content'] as String?,
      thumbUrl: json['thumb_url'] as String?,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$TransferMessageDataToJson(
        TransferMessageData instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'conversation_id': instance.conversationId,
      'user_id': instance.userId,
      'category': instance.category,
      'content': instance.content,
      'media_url': instance.mediaUrl,
      'media_mime_type': instance.mediaMimeType,
      'media_size': instance.mediaSize,
      'media_duration': instance.mediaDuration,
      'media_width': instance.mediaWidth,
      'media_height': instance.mediaHeight,
      'media_hash': instance.mediaHash,
      'thumb_image': instance.thumbImage,
      'media_key': instance.mediaKey,
      'media_digest': instance.mediaDigest,
      'media_status': _$MediaStatusEnumMap[instance.mediaStatus],
      'status': _$MessageStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'action': instance.action,
      'participant_id': instance.participantId,
      'snapshot_id': instance.snapshotId,
      'hyperlink': instance.hyperlink,
      'name': instance.name,
      'album_id': instance.albumId,
      'sticker_id': instance.stickerId,
      'shared_user_id': instance.sharedUserId,
      'media_waveform': instance.mediaWaveform,
      'quote_message_id': instance.quoteMessageId,
      'quote_content': instance.quoteContent,
      'thumb_url': instance.thumbUrl,
      'caption': instance.caption,
    };

const _$MessageStatusEnumMap = {
  MessageStatus.failed: 'FAILED',
  MessageStatus.unknown: 'UNKNOWN',
  MessageStatus.sending: 'SENDING',
  MessageStatus.sent: 'SENT',
  MessageStatus.delivered: 'DELIVERED',
  MessageStatus.read: 'READ',
};

const _$MediaStatusEnumMap = {
  MediaStatus.pending: 'pending',
  MediaStatus.done: 'done',
  MediaStatus.canceled: 'canceled',
  MediaStatus.expired: 'expired',
  MediaStatus.read: 'read',
};
