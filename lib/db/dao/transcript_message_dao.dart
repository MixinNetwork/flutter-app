import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../enum/media_status.dart';
import '../../utils/extension/extension.dart';
import '../database_event_bus.dart';
import '../event.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'transcript_message_dao.g.dart';

@DriftAccessor(include: {'../moor/dao/transcript_message.drift'})
class TranscriptMessageDao extends DatabaseAccessor<MixinDatabase>
    with _$TranscriptMessageDaoMixin {
  TranscriptMessageDao(super.db);

  Future<void> insertAll(
    List<TranscriptMessage> transcripts, {
    InsertMode mode = InsertMode.insertOrReplace,
  }) =>
      batch((batch) =>
              batch.insertAll(db.transcriptMessages, transcripts, mode: mode))
          .then((value) {
        DataBaseEventBus.instance.updateTranscriptMessage(
            transcripts.map((e) => MiniTranscriptMessage(
                  transcriptId: e.transcriptId,
                  messageId: e.messageId,
                )));
        return value;
      });

  Selectable<TranscriptMessageItem> transactionMessageItem(String messageId) =>
      baseTranscriptMessageItem(
          (transcript, message, sender, sharedUser, sticker) =>
              transcript.transcriptId.equals(messageId),
          (transcript, message, sender, sharedUser, sticker) => maxLimit);

  SimpleSelectStatement<TranscriptMessages, TranscriptMessage>
      transcriptMessageByMessageId(String messageId, [Limit? limit]) =>
          (db.select(db.transcriptMessages)
            ..where((tbl) => tbl.messageId.equals(messageId))
            // ignore: invalid_use_of_protected_member
            ..limitExpr = limit ?? Limit(1, 0));

  SimpleSelectStatement<TranscriptMessages, TranscriptMessage>
      transcriptMessageByTranscriptId(String transcriptId) =>
          db.select(db.transcriptMessages)
            ..where((tbl) => tbl.transcriptId.equals(transcriptId))
            ..orderBy([
              (tbl) => OrderingTerm.asc(tbl.createdAt),
            ]);

  Selectable<String?> messageIdsByMessageIds(Iterable<String> messageIds) =>
      (db.selectOnly(db.transcriptMessages)
            ..addColumns([db.transcriptMessages.messageId])
            ..where(db.transcriptMessages.messageId.isIn(messageIds)))
          .map((row) => row.read(db.transcriptMessages.messageId));

  Future<void> updateTranscript({
    required String transcriptId,
    required String messageId,
    required String attachmentId,
    required String? key,
    required String? digest,
    required MediaStatus mediaStatus,
    required DateTime? mediaCreatedAt,
    required String category,
  }) =>
      (db.update(db.transcriptMessages)
            ..where((tbl) =>
                tbl.transcriptId.equals(transcriptId) &
                tbl.messageId.equals(messageId)))
          .write(
        TranscriptMessagesCompanion(
          category: Value(category),
          mediaStatus: Value(mediaStatus),
          mediaKey: Value(key),
          mediaDigest: Value(digest),
          content: Value(attachmentId),
          mediaCreatedAt: Value(mediaCreatedAt),
        ),
      )
          .then((value) {
        DataBaseEventBus.instance.updateTranscriptMessage([
          MiniTranscriptMessage(
            transcriptId: transcriptId,
            messageId: messageId,
          )
        ]);
      });

  Future<String> generateTranscriptMessageFts5Content(
    List<TranscriptMessage> transcriptMessages,
  ) async {
    final contents = await Future.wait(transcriptMessages.where((transcript) {
      final category = transcript.category;
      return category.isText ||
          category.isPost ||
          category.isData ||
          category.isContact;
    }).map((transcript) async {
      final category = transcript.category;
      if (category.isData) {
        return transcript.mediaName;
      }

      if (category.isContact &&
          (transcript.sharedUserId?.isNotEmpty ?? false)) {
        return db.userDao
            .userFullNameByUserId(transcript.sharedUserId!)
            .getSingleOrNull();
      }

      return transcript.content;
    }));

    return contents.nonNulls.join(' ');
  }

  Future<List<TranscriptMessage>> getTranscriptMessages({
    required int limit,
    required int offset,
  }) =>
      (db.select(db.transcriptMessages)
            ..orderBy([(t) => OrderingTerm.desc(t.rowId)])
            ..limit(limit, offset: offset))
          .get();
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
        pinned: false,
      );
}
