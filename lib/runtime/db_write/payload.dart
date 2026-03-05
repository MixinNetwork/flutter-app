import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;

import '../../db/dao/circle_dao.dart';
import '../../db/mixin_database.dart' as db;
import '../../enum/media_status.dart';

class DbWriteUpdateConversationPayload {
  const DbWriteUpdateConversationPayload({
    required this.conversation,
    required this.currentUserId,
  });

  final sdk.ConversationResponse conversation;
  final String currentUserId;
}

class DbWriteDeleteJobsPayload {
  const DbWriteDeleteJobsPayload({required this.jobIds});

  final List<String> jobIds;
}

class DbWriteUpdateJobRunStatePayload {
  const DbWriteUpdateJobRunStatePayload({
    required this.jobId,
    required this.createdAt,
    required this.runCount,
  });

  final String jobId;
  final DateTime createdAt;
  final int runCount;
}

class DbWriteCirclePayload {
  const DbWriteCirclePayload({required this.circle});

  final db.Circle circle;
}

class DbWriteCircleConversationsPayload {
  const DbWriteCircleConversationsPayload({required this.items});

  final List<db.CircleConversation> items;
}

class DbWriteReplaceParticipantsPayload {
  const DbWriteReplaceParticipantsPayload({
    required this.conversationId,
    required this.participants,
  });

  final String conversationId;
  final List<db.Participant> participants;
}

class DbWriteReplaceParticipantSessionsPayload {
  const DbWriteReplaceParticipantSessionsPayload({
    required this.conversationId,
    required this.sessions,
  });

  final String conversationId;
  final List<db.ParticipantSessionData> sessions;
}

class DbWriteInsertParticipantSessionsPayload {
  const DbWriteInsertParticipantSessionsPayload({
    required this.sessions,
  });

  final List<db.ParticipantSessionData> sessions;
}

class DbWriteDeleteCircleConversationPayload {
  const DbWriteDeleteCircleConversationPayload({
    required this.conversationId,
    required this.circleId,
  });

  final String conversationId;
  final String circleId;
}

class DbWriteUpsertContactConversationPayload {
  const DbWriteUpsertContactConversationPayload({
    required this.conversationId,
    required this.currentUserId,
    required this.recipientId,
    required this.createdAt,
  });

  final String conversationId;
  final String currentUserId;
  final String recipientId;
  final DateTime createdAt;
}

class DbWriteUpdateUserMuteUntilPayload {
  const DbWriteUpdateUserMuteUntilPayload({
    required this.userId,
    required this.muteUntil,
  });

  final String userId;
  final String muteUntil;
}

class DbWriteUpdateConversationMuteUntilPayload {
  const DbWriteUpdateConversationMuteUntilPayload({
    required this.conversationId,
    required this.muteUntil,
  });

  final String conversationId;
  final String muteUntil;
}

class DbWriteUpdateConversationCodeUrlPayload {
  const DbWriteUpdateConversationCodeUrlPayload({
    required this.conversationId,
    required this.codeUrl,
  });

  final String conversationId;
  final String codeUrl;
}

class DbWriteUpdateConversationStatusPayload {
  const DbWriteUpdateConversationStatusPayload({
    required this.conversationId,
    required this.status,
  });

  final String conversationId;
  final sdk.ConversationStatus status;
}

class DbWriteUpdateConversationExpireInPayload {
  const DbWriteUpdateConversationExpireInPayload({
    required this.conversationId,
    required this.expireIn,
  });

  final String conversationId;
  final int expireIn;
}

class DbWriteUpdateParticipantRolePayload {
  const DbWriteUpdateParticipantRolePayload({
    required this.conversationId,
    required this.participantId,
    required this.role,
  });

  final String conversationId;
  final String participantId;
  final sdk.ParticipantRole? role;
}

class DbWriteRemoveParticipantAndResetSessionsPayload {
  const DbWriteRemoveParticipantAndResetSessionsPayload({
    required this.conversationId,
    required this.participantId,
  });

  final String conversationId;
  final String participantId;
}

class DbWriteCleanupParticipantSessionPayload {
  const DbWriteCleanupParticipantSessionPayload({required this.sessionId});

  final String sessionId;
}

class DbWriteUpdateMessageStatusPayload {
  const DbWriteUpdateMessageStatusPayload({
    required this.messageId,
    required this.status,
  });

  final String messageId;
  final sdk.MessageStatus status;
}

class DbWriteParseMentionDataPayload {
  const DbWriteParseMentionDataPayload({
    required this.content,
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.quoteContentJson,
    required this.currentUserId,
    required this.currentUserIdentityNumber,
  });

  final String? content;
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? quoteContentJson;
  final String currentUserId;
  final String currentUserIdentityNumber;
}

class DbWriteUpdateExpiredMessageExpireAtPayload {
  const DbWriteUpdateExpiredMessageExpireAtPayload({
    required this.messageId,
    required this.expireAt,
  });

  final String messageId;
  final int? expireAt;
}

class DbWriteInsertExpiredMessagePayload {
  const DbWriteInsertExpiredMessagePayload({
    required this.messageId,
    required this.expireIn,
    required this.expireAt,
  });

  final String messageId;
  final int expireIn;
  final int expireAt;
}

class DbWriteTakeConversationUnseenPayload {
  const DbWriteTakeConversationUnseenPayload({
    required this.currentUserId,
    required this.conversationId,
  });

  final String currentUserId;
  final String conversationId;
}

class DbWriteMiniMessagePayload {
  const DbWriteMiniMessagePayload({
    required this.messageId,
    required this.conversationId,
  });

  final String messageId;
  final String conversationId;
}

class DbWriteMarkMessagesReadPayload {
  const DbWriteMarkMessagesReadPayload({
    required this.items,
  });

  final List<DbWriteMiniMessagePayload> items;
}

class DbWriteDeleteMessagePayload {
  const DbWriteDeleteMessagePayload({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;
}

class DbWriteDeleteMessagesByConversationPayload {
  const DbWriteDeleteMessagesByConversationPayload({
    required this.conversationId,
  });

  final String conversationId;
}

class DbWriteUpdateConversationDraftPayload {
  const DbWriteUpdateConversationDraftPayload({
    required this.conversationId,
    required this.draft,
  });

  final String conversationId;
  final String draft;
}

class DbWriteUpdateCircleOrdersPayload {
  const DbWriteUpdateCircleOrdersPayload({required this.items});

  final List<ConversationCircleItem> items;
}

class DbWriteFavoriteAppsPayload {
  const DbWriteFavoriteAppsPayload({
    required this.userId,
    required this.apps,
  });

  final String userId;
  final List<sdk.FavoriteApp> apps;
}

class DbWriteReplaceStickersByAlbumPayload {
  const DbWriteReplaceStickersByAlbumPayload({
    required this.relationships,
    required this.stickers,
  });

  final List<db.StickerRelationship> relationships;
  final List<db.StickersCompanion> stickers;
}

class DbWriteInsertStickerAndRelationshipPayload {
  const DbWriteInsertStickerAndRelationshipPayload({
    required this.sticker,
    required this.relationship,
  });

  final db.StickersCompanion sticker;
  final db.StickerRelationship relationship;
}

class DbWriteUpdateStickerUsedAtPayload {
  const DbWriteUpdateStickerUsedAtPayload({
    required this.albumId,
    required this.stickerId,
    required this.usedAt,
  });

  final String? albumId;
  final String stickerId;
  final DateTime usedAt;
}

class DbWriteUpdateStickerAlbumAddedPayload {
  const DbWriteUpdateStickerAlbumAddedPayload({
    required this.albumId,
    required this.added,
  });

  final String albumId;
  final bool added;
}

class DbWriteUpdateStickerAlbumOrdersPayload {
  const DbWriteUpdateStickerAlbumOrdersPayload({required this.albums});

  final List<db.StickerAlbum> albums;
}

class DbWriteUpdateSafeSnapshotMessagePayload {
  const DbWriteUpdateSafeSnapshotMessagePayload({
    required this.messageId,
    required this.snapshotId,
  });

  final String messageId;
  final String snapshotId;
}

class DbWriteUpsertAssetAndChainPayload {
  const DbWriteUpsertAssetAndChainPayload({
    required this.asset,
    required this.chain,
  });

  final sdk.Asset asset;
  final sdk.Chain chain;
}

class DbWriteUpsertTokenAndChainPayload {
  const DbWriteUpsertTokenAndChainPayload({
    required this.token,
    required this.chain,
  });

  final sdk.Token token;
  final sdk.Chain chain;
}

class DbWriteInsertSendMessagePayload {
  const DbWriteInsertSendMessagePayload({
    required this.message,
    required this.currentUserId,
    required this.expireIn,
    required this.cleanDraft,
    this.silent = false,
    this.ftsContent,
  });

  final db.Message message;
  final String currentUserId;
  final int expireIn;
  final bool cleanDraft;
  final bool silent;
  final String? ftsContent;
}

class DbWriteInsertMessageHistoryPayload {
  const DbWriteInsertMessageHistoryPayload({required this.messageId});

  final String messageId;
}

class DbWriteInsertMessageHistoryBatchPayload {
  const DbWriteInsertMessageHistoryBatchPayload({required this.messageIds});

  final List<String> messageIds;
}

class DbWriteInsertResendSessionMessagePayload {
  const DbWriteInsertResendSessionMessagePayload({
    required this.message,
  });

  final db.ResendSessionMessage message;
}

class DbWriteUpdateAttachmentMessageContentAndStatusPayload {
  const DbWriteUpdateAttachmentMessageContentAndStatusPayload({
    required this.messageId,
    required this.content,
    this.key,
    this.digest,
  });

  final String messageId;
  final String content;
  final String? key;
  final String? digest;
}

class DbWriteUpdateMessageContentAndStatusPayload {
  const DbWriteUpdateMessageContentAndStatusPayload({
    required this.messageId,
    required this.content,
    required this.status,
  });

  final String messageId;
  final String? content;
  final sdk.MessageStatus status;
}

class DbWriteUpdateMessageContentPayload {
  const DbWriteUpdateMessageContentPayload({
    required this.messageId,
    required this.content,
  });

  final String messageId;
  final String content;
}

class DbWriteUpdateMessageCategoryPayload {
  const DbWriteUpdateMessageCategoryPayload({
    required this.messageId,
    required this.category,
  });

  final String messageId;
  final String category;
}

class DbWriteDeleteResendSessionMessagePayload {
  const DbWriteDeleteResendSessionMessagePayload({required this.messageId});

  final String messageId;
}

class DbWriteUpdateAttachmentMessagePayload {
  const DbWriteUpdateAttachmentMessagePayload({
    required this.messageId,
    required this.status,
    required this.content,
    required this.mediaMimeType,
    required this.mediaSize,
    required this.mediaStatus,
    required this.mediaWidth,
    required this.mediaHeight,
    required this.mediaDigest,
    required this.mediaKey,
    required this.mediaWaveform,
    required this.caption,
    required this.name,
    required this.thumbImage,
    required this.mediaDuration,
  });

  final String messageId;
  final sdk.MessageStatus status;
  final String content;
  final String? mediaMimeType;
  final int? mediaSize;
  final MediaStatus mediaStatus;
  final int? mediaWidth;
  final int? mediaHeight;
  final String? mediaDigest;
  final String? mediaKey;
  final String? mediaWaveform;
  final String? caption;
  final String? name;
  final String? thumbImage;
  final String? mediaDuration;
}

class DbWriteUpdateStickerMessagePayload {
  const DbWriteUpdateStickerMessagePayload({
    required this.messageId,
    required this.status,
    required this.stickerId,
  });

  final String messageId;
  final sdk.MessageStatus status;
  final String stickerId;
}

class DbWriteUpdateContactMessagePayload {
  const DbWriteUpdateContactMessagePayload({
    required this.messageId,
    required this.status,
    required this.sharedUserId,
  });

  final String messageId;
  final sdk.MessageStatus status;
  final String sharedUserId;
}

class DbWriteUpdateLiveMessagePayload {
  const DbWriteUpdateLiveMessagePayload({
    required this.messageId,
    required this.width,
    required this.height,
    required this.url,
    required this.thumbUrl,
    required this.status,
  });

  final String messageId;
  final int width;
  final int height;
  final String url;
  final String thumbUrl;
  final sdk.MessageStatus status;
}

class DbWriteUpdateTranscriptMessagePayload {
  const DbWriteUpdateTranscriptMessagePayload({
    required this.messageId,
    required this.content,
    required this.mediaSize,
    required this.mediaStatus,
    required this.status,
  });

  final String messageId;
  final String? content;
  final int? mediaSize;
  final MediaStatus? mediaStatus;
  final sdk.MessageStatus status;
}

class DbWriteDeletePendingSafeSnapshotByHashPayload {
  const DbWriteDeletePendingSafeSnapshotByHashPayload({
    required this.depositHash,
  });

  final String depositHash;
}

class DbWriteRecallMessagePayload {
  const DbWriteRecallMessagePayload({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;
}

class DbWriteDeleteMessageMentionPayload {
  const DbWriteDeleteMessageMentionPayload({required this.messageMention});

  final db.MessageMention messageMention;
}

class DbWriteUpdateQuoteContentByQuoteIdPayload {
  const DbWriteUpdateQuoteContentByQuoteIdPayload({
    required this.conversationId,
    required this.quoteMessageId,
    required this.content,
  });

  final String conversationId;
  final String quoteMessageId;
  final String? content;
}

class DbWriteInsertTranscriptMessagesPayload {
  const DbWriteInsertTranscriptMessagesPayload({required this.transcripts});

  final List<db.TranscriptMessage> transcripts;
}

class DbWriteUpdateTranscriptPayload {
  const DbWriteUpdateTranscriptPayload({
    required this.transcriptId,
    required this.messageId,
    required this.attachmentId,
    required this.key,
    required this.digest,
    required this.mediaStatus,
    required this.mediaCreatedAt,
    required this.category,
  });

  final String transcriptId;
  final String messageId;
  final String attachmentId;
  final String? key;
  final String? digest;
  final MediaStatus mediaStatus;
  final DateTime? mediaCreatedAt;
  final String category;
}

class DbWriteUpdateMessageMediaStatusPayload {
  const DbWriteUpdateMessageMediaStatusPayload({
    required this.messageId,
    required this.status,
  });

  final String messageId;
  final MediaStatus status;
}

class DbWritePinAndInsertPinMessagesPayload {
  const DbWritePinAndInsertPinMessagesPayload({
    required this.pinMessages,
    required this.systemMessages,
    required this.currentUserId,
  });

  final List<db.PinMessage> pinMessages;
  final List<db.Message> systemMessages;
  final String currentUserId;
}

class DbWriteDeletePinMessagesPayload {
  const DbWriteDeletePinMessagesPayload({required this.messageIds});

  final List<String> messageIds;
}

class DbWriteUpdateGiphyMessagePayload {
  const DbWriteUpdateGiphyMessagePayload({
    required this.messageId,
    required this.mediaUrl,
    required this.mediaSize,
    required this.thumbImage,
  });

  final String messageId;
  final String mediaUrl;
  final int mediaSize;
  final String? thumbImage;
}

class DbWriteInsertFtsPayload {
  const DbWriteInsertFtsPayload({
    required this.message,
    this.content,
  });

  final db.Message message;
  final String? content;
}

class DbWriteMigrateFtsInsertBatchPayload {
  const DbWriteMigrateFtsInsertBatchPayload({
    required this.messages,
    required this.transcriptContentMap,
  });

  final List<db.Message> messages;
  final Map<String, String> transcriptContentMap;
}

class DbWriteReplaceMigrateFtsJobPayload {
  const DbWriteReplaceMigrateFtsJobPayload({required this.messageRowId});

  final int? messageRowId;
}
