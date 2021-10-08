import 'dart:core';

import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart';

part 'sending_transcript_message.g.dart';

@JsonSerializable()
class SendingTranscriptMessage {
  SendingTranscriptMessage({
    required this.transcriptId,
    required this.messageId,
    this.userId,
    this.userFullName,
    required this.category,
    required this.createdAt,
    this.content,
    this.mediaName,
    this.mediaSize,
    this.mediaWidth,
    this.mediaHeight,
    this.mediaMimeType,
    this.mediaDuration,
    this.mediaWaveform,
    this.thumbImage,
    this.thumbUrl,
    this.mediaKey,
    this.mediaDigest,
    this.mediaCreatedAt,
    this.stickerId,
    this.sharedUserId,
    this.mentions,
    this.quoteId,
    this.quoteContent,
    this.caption,
  });

  @JsonKey(name: 'transcript_id')
  String transcriptId;
  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'user_full_name')
  final String? userFullName;
  @JsonKey(name: 'category')
  String category;
  @JsonKey(
    name: 'created_at',
    // toJson: _dateTimeToJson,
  )
  final DateTime createdAt;
  @JsonKey(name: 'content')
  final String? content;
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
  final String? mediaDuration;
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
  @JsonKey(
    name: 'media_created_at',
    // toJson: _dateTimeToJson,
  )
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
  String? quoteContent;
  @JsonKey(name: 'caption')
  final String? caption;

  static SendingTranscriptMessage fromSendingMessage(
          TranscriptMessage transcriptMessage) =>
      SendingTranscriptMessage(
        transcriptId: transcriptMessage.transcriptId,
        messageId: transcriptMessage.messageId,
        userId: transcriptMessage.userId,
        userFullName: transcriptMessage.userFullName,
        category: transcriptMessage.category,
        createdAt: transcriptMessage.createdAt,
        content: transcriptMessage.content,
        mediaName: transcriptMessage.mediaName,
        mediaSize: transcriptMessage.mediaSize,
        mediaWidth: transcriptMessage.mediaWidth,
        mediaHeight: transcriptMessage.mediaHeight,
        mediaMimeType: transcriptMessage.mediaMimeType,
        mediaDuration: transcriptMessage.mediaDuration,
        mediaWaveform: transcriptMessage.mediaWaveform,
        thumbImage: transcriptMessage.thumbImage,
        thumbUrl: transcriptMessage.thumbUrl,
        mediaKey: transcriptMessage.mediaKey,
        mediaDigest: transcriptMessage.mediaDigest,
        mediaCreatedAt: transcriptMessage.mediaCreatedAt,
        stickerId: transcriptMessage.stickerId,
        sharedUserId: transcriptMessage.sharedUserId,
        mentions: transcriptMessage.mentions,
        quoteId: transcriptMessage.quoteId,
        quoteContent: transcriptMessage.quoteContent,
        caption: transcriptMessage.caption,
      );

  Map<String, dynamic> toJson() => _$SendingTranscriptMessageToJson(this);
}

int? _dateTimeToJson(DateTime? value) => value?.millisecondsSinceEpoch;
