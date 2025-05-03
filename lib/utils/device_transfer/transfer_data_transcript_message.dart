import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;
import '../../enum/media_status.dart';

part 'transfer_data_transcript_message.g.dart';

DateTime? _safeDateTimeFromJson(String? json) {
  if (json == null) {
    return null;
  }
  return DateTime.tryParse(json);
}

@JsonSerializable()
@MediaStatusJsonConverter()
class TransferDataTranscriptMessage {
  const TransferDataTranscriptMessage({
    required this.transcriptId,
    required this.messageId,
    required this.userId,
    required this.userFullName,
    required this.category,
    required this.createdAt,
    required this.content,
    required this.mediaUrl,
    required this.mediaName,
    required this.mediaSize,
    required this.mediaWidth,
    required this.mediaHeight,
    required this.mediaMimeType,
    required this.mediaDuration,
    required this.mediaStatus,
    required this.mediaWaveform,
    required this.thumbImage,
    required this.thumbUrl,
    required this.mediaKey,
    required this.mediaDigest,
    required this.mediaCreatedAt,
    required this.stickerId,
    required this.sharedUserId,
    required this.mentions,
    required this.quoteId,
    required this.quoteContent,
    required this.caption,
  });

  factory TransferDataTranscriptMessage.fromJson(Map<String, dynamic> json) =>
      _$TransferDataTranscriptMessageFromJson(json);

  factory TransferDataTranscriptMessage.fromDbTranscriptMessage(
    db.TranscriptMessage data,
  ) => TransferDataTranscriptMessage(
    transcriptId: data.transcriptId,
    messageId: data.messageId,
    userId: data.userId,
    userFullName: data.userFullName,
    category: data.category,
    createdAt: data.createdAt,
    content: data.content,
    mediaUrl: data.mediaUrl,
    mediaName: data.mediaName,
    mediaSize: data.mediaSize,
    mediaWidth: data.mediaWidth,
    mediaHeight: data.mediaHeight,
    mediaMimeType: data.mediaMimeType,
    mediaDuration:
        data.mediaDuration == null ? null : int.tryParse(data.mediaDuration!),
    mediaStatus:
        data.mediaStatus == MediaStatus.pending
            ? MediaStatus.canceled
            : data.mediaStatus,
    mediaWaveform: data.mediaWaveform,
    thumbImage: data.thumbImage,
    thumbUrl: data.thumbUrl,
    mediaKey: data.mediaKey,
    mediaDigest: data.mediaDigest,
    mediaCreatedAt: data.mediaCreatedAt,
    stickerId: data.stickerId,
    sharedUserId: data.sharedUserId,
    mentions: data.mentions,
    quoteId: data.quoteId,
    quoteContent: data.quoteContent,
    caption: data.caption,
  );

  @JsonKey(name: 'transcript_id')
  final String transcriptId;

  @JsonKey(name: 'message_id')
  final String messageId;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'user_full_name')
  final String? userFullName;

  @JsonKey(name: 'category')
  final String category;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'content')
  final String? content;

  @JsonKey(name: 'media_url')
  final String? mediaUrl;

  @JsonKey(name: 'media_name')
  final String? mediaName;

  @JsonKey(name: 'media_size')
  final int? mediaSize;

  @JsonKey(name: 'media_width')
  final int? mediaWidth;

  @JsonKey(name: 'media_height')
  final int? mediaHeight;

  @JsonKey(name: 'media_mime_type')
  final String? mediaMimeType;

  @JsonKey(name: 'media_duration')
  final int? mediaDuration;

  @JsonKey(name: 'media_status')
  final MediaStatus? mediaStatus;

  @JsonKey(name: 'media_waveform')
  final String? mediaWaveform;

  @JsonKey(name: 'thumb_image')
  final String? thumbImage;

  @JsonKey(name: 'thumb_url')
  final String? thumbUrl;

  @JsonKey(name: 'media_key')
  final String? mediaKey;

  @JsonKey(name: 'media_digest')
  final String? mediaDigest;

  @JsonKey(name: 'media_created_at', fromJson: _safeDateTimeFromJson)
  final DateTime? mediaCreatedAt;

  @JsonKey(name: 'sticker_id')
  final String? stickerId;

  @JsonKey(name: 'shared_user_id')
  final String? sharedUserId;

  @JsonKey(name: 'mentions')
  final String? mentions;

  @JsonKey(name: 'quote_id')
  final String? quoteId;

  @JsonKey(name: 'quote_content')
  final String? quoteContent;

  @JsonKey(name: 'caption')
  final String? caption;

  Map<String, dynamic> toJson() => _$TransferDataTranscriptMessageToJson(this);

  db.TranscriptMessage toDbTranscriptMessage() => db.TranscriptMessage(
    transcriptId: transcriptId,
    messageId: messageId,
    userId: userId,
    userFullName: userFullName,
    category: category,
    createdAt: createdAt,
    content: content,
    mediaUrl: mediaUrl,
    mediaName: mediaName,
    mediaSize: mediaSize,
    mediaWidth: mediaWidth,
    mediaHeight: mediaHeight,
    mediaMimeType: mediaMimeType,
    mediaDuration: mediaDuration?.toString(),
    mediaStatus:
        mediaStatus == MediaStatus.pending ? MediaStatus.canceled : mediaStatus,
    mediaWaveform: mediaWaveform,
    thumbImage: thumbImage,
    thumbUrl: thumbUrl,
    mediaKey: mediaKey,
    mediaDigest: mediaDigest,
    mediaCreatedAt: mediaCreatedAt,
    stickerId: stickerId,
    sharedUserId: sharedUserId,
    mentions: mentions,
    quoteId: quoteId,
    quoteContent: quoteContent,
    caption: caption,
  );

  @override
  String toString() => '$TransferDataTranscriptMessage($transcriptId)';
}
