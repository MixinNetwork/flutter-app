import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../enum/media_status.dart';

part 'transfer_message_data.g.dart';

@JsonSerializable()
class TransferMessageData {
  TransferMessageData({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.category,
    required this.createdAt,
    required this.status,
    this.content,
    this.mediaUrl,
    this.mediaMimeType,
    this.mediaSize,
    this.mediaDuration,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaHash,
    this.thumbImage,
    this.mediaKey,
    this.mediaDigest,
    this.mediaStatus,
    this.action,
    this.participantId,
    this.snapshotId,
    this.hyperlink,
    this.name,
    this.albumId,
    this.stickerId,
    this.sharedUserId,
    this.mediaWaveform,
    this.quoteMessageId,
    this.quoteContent,
    this.thumbUrl,
    this.caption,
  });

  factory TransferMessageData.fromJson(Map<String, dynamic> json) =>
      _$TransferMessageDataFromJson(json);

  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'category')
  final String category;
  @JsonKey(name: 'content')
  final String? content;
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @JsonKey(name: 'media_mime_type')
  final String? mediaMimeType;
  @JsonKey(name: 'media_size')
  final int? mediaSize;
  @JsonKey(name: 'media_duration')
  final String? mediaDuration;
  @JsonKey(name: 'media_width')
  final int? mediaWidth;
  @JsonKey(name: 'media_height')
  final int? mediaHeight;
  @JsonKey(name: 'media_hash')
  final String? mediaHash;
  @JsonKey(name: 'thumb_image')
  final String? thumbImage;
  @JsonKey(name: 'media_key')
  final String? mediaKey;
  @JsonKey(name: 'media_digest')
  final String? mediaDigest;
  @JsonKey(name: 'media_status')
  final MediaStatus? mediaStatus;
  @JsonKey(name: 'status')
  final MessageStatus status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'action')
  final String? action;
  @JsonKey(name: 'participant_id')
  final String? participantId;
  @JsonKey(name: 'snapshot_id')
  final String? snapshotId;
  @JsonKey(name: 'hyperlink')
  final String? hyperlink;
  @JsonKey(name: 'name')
  final String? name;
  @JsonKey(name: 'album_id')
  final String? albumId;
  @JsonKey(name: 'sticker_id')
  final String? stickerId;
  @JsonKey(name: 'shared_user_id')
  final String? sharedUserId;
  @JsonKey(name: 'media_waveform')
  final String? mediaWaveform;
  @JsonKey(name: 'quote_message_id')
  final String? quoteMessageId;
  @JsonKey(name: 'quote_content')
  final String? quoteContent;
  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;
  @JsonKey(name: 'caption')
  final String? caption;

  Map<String, dynamic> toJson() => _$TransferMessageDataToJson(this);
}
