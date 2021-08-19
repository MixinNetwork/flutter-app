import 'package:flutter_app/db/util/util.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'transcript_message_dao.g.dart';

@UseDao(tables: [TranscriptMessages])
class TranscriptMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$TranscriptMessageDaoMixin {
  TranscriptMessageDao(MixinDatabase db) : super(db);

  Future<void> insertAll(List<TranscriptMessage> transcripts) =>
      batch((batch) => batch.insertAll(db.transcriptMessages, transcripts,
          mode: InsertMode.insertOrReplace));

  Selectable<TranscriptMessageItem> transactionMessageItem(String messageId) =>
      db.baseTranscriptMessageItem(
          (transcript, message, sender, sharedUser, sticker) =>
              transcript.transcriptId.equals(messageId),
          (transcript, message, sender, sharedUser, sticker) => maxLimit);

  Selectable<MediaStatus?> mediaStatus(String messageId) =>
      (db.selectOnly(db.transcriptMessages)
            ..addColumns([db.transcriptMessages.mediaStatus])
            ..where(db.transcriptMessages.messageId.equals(messageId))
            ..limit(1))
          .map((row) => db.transcriptMessages.mediaStatus.converter
              .mapToDart(row.read(db.transcriptMessages.mediaStatus)));
}

extension TranscriptMessageItemExtension on TranscriptMessageItem {
  MessageItem get messageItem => MessageItem(
        messageId: messageId,
        conversationId: conversationId,
        type: type,
        content: content,
        createdAt: createdAt,
        status: status,
        mediaStatus: mediaStatus,
        mediaWaveform: mediaWaveform,
        mediaName: mediaName,
        mediaMimeType: mediaMimeType,
        mediaSize: mediaSize,
        mediaWidth: mediaWidth,
        mediaHeight: mediaHeight,
        thumbImage: thumbImage,
        thumbUrl: thumbUrl,
        mediaUrl: mediaUrl,
        mediaDuration: mediaDuration,
        quoteId: quoteId,
        quoteContent: quoteContent,
        sharedUserId: sharedUserId,
        userId: userId ?? '',
        userFullName: userFullName,
        userIdentityNumber: userIdentityNumber ?? '',
        appId: appId,
        relationship: relationship,
        avatarUrl: avatarUrl,
        sharedUserFullName: sharedUserFullName,
        sharedUserIdentityNumber: sharedUserIdentityNumber,
        sharedUserAvatarUrl: sharedUserAvatarUrl,
        sharedUserIsVerified: sharedUserIsVerified,
        sharedUserAppId: sharedUserAppId,
        assetUrl: assetUrl,
        assetWidth: assetWidth,
        assetHeight: assetHeight,
        stickerId: stickerId,
        assetName: assetName,
        assetType: assetType,
      );
}
