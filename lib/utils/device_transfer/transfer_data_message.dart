import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/converter/millis_date_converter.dart';
import '../../db/mixin_database.dart' as db;
import '../../enum/media_status.dart';

part 'transfer_data_message.g.dart';

@JsonSerializable()
@MediaStatusJsonConverter()
class TransferDataMessage {
  TransferDataMessage({
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

  factory TransferDataMessage.fromJson(Map<String, dynamic> json) =>
      _$TransferDataMessageFromJson(json);

  factory TransferDataMessage.fromDbMessage(db.Message data) {
    var quoteContent = data.quoteContent;
    if (quoteContent != null) {
      try {
        final map = jsonDecode(quoteContent) as Map<String, dynamic>;
        final createdAtJson = map['created_at'] ?? map['createdAt'];
        final createdAt =
            createdAtJson is String
                ? DateTime.parse(createdAtJson)
                : const MillisDateConverter().fromSql(createdAtJson as int);
        map['created_at'] = createdAt.toIso8601String();
        map['createdAt'] = createdAt.toIso8601String();
        quoteContent = jsonEncode(map);
      } catch (error, stacktrace) {
        e('failed to parse quote content: $error, stacktrace: $stacktrace');
      }
    }
    return TransferDataMessage(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.userId,
      category: data.category,
      createdAt: data.createdAt,
      status: data.status,
      content: data.content,
      mediaUrl: data.mediaUrl,
      mediaMimeType: data.mediaMimeType,
      mediaSize: data.mediaSize,
      mediaDuration: data.mediaDuration,
      mediaWidth: data.mediaWidth,
      mediaHeight: data.mediaHeight,
      mediaHash: data.mediaHash,
      thumbImage: data.thumbImage,
      mediaKey: data.mediaKey,
      mediaDigest: data.mediaDigest,
      mediaStatus:
          data.mediaStatus == MediaStatus.pending
              ? MediaStatus.canceled
              : data.mediaStatus,
      action: data.action,
      participantId: data.participantId,
      snapshotId: data.snapshotId,
      hyperlink: data.hyperlink,
      name: data.name,
      albumId: data.albumId,
      stickerId: data.stickerId,
      sharedUserId: data.sharedUserId,
      mediaWaveform: data.mediaWaveform,
      quoteMessageId: data.quoteMessageId,
      quoteContent: quoteContent,
      thumbUrl: data.thumbUrl,
      caption: data.caption,
    );
  }

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

  Map<String, dynamic> toJson() => _$TransferDataMessageToJson(this);

  db.Message toDbMessage() => db.Message(
    messageId: messageId,
    conversationId: conversationId,
    userId: userId,
    category: category,
    content: content,
    mediaUrl: mediaUrl,
    mediaMimeType: mediaMimeType,
    mediaSize: mediaSize,
    mediaDuration: mediaDuration,
    mediaWidth: mediaWidth,
    mediaHeight: mediaHeight,
    mediaHash: mediaHash,
    thumbImage: thumbImage,
    mediaKey: mediaKey,
    mediaDigest: mediaDigest,
    mediaStatus:
        mediaStatus == MediaStatus.pending ? MediaStatus.canceled : mediaStatus,
    status: status,
    createdAt: createdAt,
    action: action,
    participantId: participantId,
    snapshotId: snapshotId,
    hyperlink: hyperlink,
    name: name,
    albumId: albumId,
    stickerId: stickerId,
    sharedUserId: sharedUserId,
    mediaWaveform: mediaWaveform,
    quoteMessageId: quoteMessageId,
    quoteContent: quoteContent,
    thumbUrl: thumbUrl,
    caption: caption,
  );

  @override
  String toString() => 'TransferMessageData: $messageId';
}
