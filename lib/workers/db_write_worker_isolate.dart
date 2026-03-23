import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' as sdk;
import 'package:stream_channel/isolate_channel.dart';

import '../constants/constants.dart';
import '../db/dao/message_dao.dart';
import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../db/extension/job.dart';
import '../db/extension/message.dart';
import '../db/fts_database.dart';
import '../db/mixin_database.dart' as db;
import '../runtime/db_write/method.dart';
import '../runtime/db_write/payload.dart';
import '../runtime/isolate/protocol.dart';
import '../runtime/isolate/router.dart';
import '../runtime/sync/tick_patch_batcher.dart';
import '../utils/logger.dart';

class DbWriteWorkerInitParams {
  DbWriteWorkerInitParams({
    required this.sendPort,
    required this.identityNumber,
  });

  final SendPort sendPort;
  final String identityNumber;
}

Future<void> startDbWriteWorkerIsolate(DbWriteWorkerInitParams params) async {
  final isolateChannel = IsolateChannel<dynamic>.connectSend(params.sendPort);
  final router = IsolateRouter.worker(
    inbound: isolateChannel.stream,
    sendMessage: isolateChannel.sink.add,
  );

  final runner = _DbWriteRunner(
    identityNumber: params.identityNumber,
    emitEvent: router.sendEvent,
  );
  await runner.init();
  router.commands.listen((command) async {
    if (command is! ExitWorkerCommand) return;
    await runner.dispose();
    Isolate.exit();
  });
  router.rpcRequests.listen((request) async {
    try {
      final result = await runner.handleRequest(request);
      router.sendRpcResponse(
        RpcSuccessResponse(requestId: request.requestId, result: result),
      );
    } catch (error, stackTrace) {
      e('db_write_worker rpc error: $error, $stackTrace');
      router.sendRpcResponse(
        RpcErrorResponse(
          requestId: request.requestId,
          code: 'db_write_failed',
          message: error.toString(),
        ),
      );
    }
  });
  router.sendReady();
}

class _DbWriteRunner {
  _DbWriteRunner({
    required this.identityNumber,
    required this.emitEvent,
  });

  final String identityNumber;
  final void Function(WorkerEvent event) emitEvent;
  late final TickPatchBatcher _patchBatcher = TickPatchBatcher(
    onFlush: (patches) => emitEvent(WorkerSyncPatchesEvent(patches: patches)),
  );

  late Database database;
  final _subscriptions = <StreamSubscription<dynamic>>[];

  Future<void> init() async {
    DataBaseEventBus.instance.legacyEventBridgeEnabled = false;
    database = Database(
      await db.connectToDatabase(identityNumber, readCount: 2),
      await FtsDatabase.connect(identityNumber),
    );
    _subscriptions.add(
      DataBaseEventBus.instance.patchStream.listen(_patchBatcher.add),
    );
  }

  Future<Object?> handleRequest(RpcRequest request) async {
    final method = DbWriteMethod.values.byName(request.method);
    switch (method) {
      case DbWriteMethod.insertUpdateUsers:
        final users = (request.payload! as List<dynamic>).cast<sdk.User>();
        await _insertUpdateUsers(users);
        return null;
      case DbWriteMethod.insertJob:
        final job = request.payload! as db.Job;
        await database.jobDao.insert(job);
        return null;
      case DbWriteMethod.insertJobs:
        final jobs = (request.payload! as List<dynamic>).cast<db.Job>();
        await database.jobDao.insertAll(jobs);
        return null;
      case DbWriteMethod.deleteJobById:
        final jobId = request.payload! as String;
        await database.jobDao.deleteJobById(jobId);
        return null;
      case DbWriteMethod.deleteJobs:
        final payload = request.payload! as DbWriteDeleteJobsPayload;
        await database.jobDao.deleteJobs(payload.jobIds);
        return null;
      case DbWriteMethod.deleteJobByAction:
        final action = request.payload! as String;
        await database.jobDao.deleteJobByAction(action);
        return null;
      case DbWriteMethod.updateJobRunState:
        final payload = request.payload! as DbWriteUpdateJobRunStatePayload;
        await (database.mixinDatabase.update(
          database.mixinDatabase.jobs,
        )..where((tbl) => tbl.jobId.equals(payload.jobId))).write(
          db.JobsCompanion(
            createdAt: Value(payload.createdAt),
            runCount: Value(payload.runCount),
          ),
        );
        return null;
      case DbWriteMethod.upsertConversation:
        final conversation = request.payload! as db.Conversation;
        await database.conversationDao.insert(conversation);
        return null;
      case DbWriteMethod.replaceParticipants:
        final payload = request.payload! as DbWriteReplaceParticipantsPayload;
        await database.participantDao.replaceAll(
          payload.conversationId,
          payload.participants,
        );
        return null;
      case DbWriteMethod.replaceParticipantSessions:
        final payload =
            request.payload! as DbWriteReplaceParticipantSessionsPayload;
        await database.participantSessionDao.replaceAll(
          payload.conversationId,
          payload.sessions,
        );
        return null;
      case DbWriteMethod.insertParticipantSessions:
        final payload =
            request.payload! as DbWriteInsertParticipantSessionsPayload;
        await database.participantSessionDao.insertAll(payload.sessions);
        return null;
      case DbWriteMethod.updateConversationStatus:
        final payload =
            request.payload! as DbWriteUpdateConversationStatusPayload;
        await database.conversationDao.updateConversationStatusById(
          payload.conversationId,
          payload.status,
        );
        return null;
      case DbWriteMethod.removeParticipantAndResetSessions:
        final payload =
            request.payload! as DbWriteRemoveParticipantAndResetSessionsPayload;
        await database.transaction(() async {
          await database.participantDao.deleteByCIdAndPId(
            payload.conversationId,
            payload.participantId,
          );
          await database.participantSessionDao.deleteByCIdAndPId(
            payload.conversationId,
            payload.participantId,
          );
          await database.participantSessionDao.emptyStatusByConversationId(
            payload.conversationId,
          );
        });
        return null;
      case DbWriteMethod.upsertApp:
        final app = request.payload! as db.App;
        await database.appDao.insert(app);
        return null;
      case DbWriteMethod.upsertUser:
        final user = request.payload! as db.User;
        await database.userDao.insert(user);
        return null;
      case DbWriteMethod.upsertParticipant:
        final participant = request.payload! as db.Participant;
        await database.participantDao.insert(participant);
        return null;
      case DbWriteMethod.upsertSdkUser:
        final user = request.payload! as sdk.User;
        await database.userDao.insertSdkUser(user);
        return null;
      case DbWriteMethod.updateConversationFromResponse:
        final payload = request.payload! as DbWriteUpdateConversationPayload;
        await database.conversationDao.updateConversation(
          payload.conversation,
          payload.currentUserId,
        );
        return null;
      case DbWriteMethod.updateConversationExpireIn:
        final payload =
            request.payload! as DbWriteUpdateConversationExpireInPayload;
        await database.conversationDao.updateConversationExpireIn(
          payload.conversationId,
          payload.expireIn,
        );
        return null;
      case DbWriteMethod.updateParticipantRole:
        final payload = request.payload! as DbWriteUpdateParticipantRolePayload;
        await database.participantDao.updateParticipantRole(
          payload.conversationId,
          payload.participantId,
          payload.role,
        );
        return null;
      case DbWriteMethod.upsertCircle:
        final payload = request.payload! as DbWriteCirclePayload;
        await database.circleDao.insertUpdate(payload.circle);
        return null;
      case DbWriteMethod.upsertCircleConversations:
        final payload = request.payload! as DbWriteCircleConversationsPayload;
        for (final item in payload.items) {
          await database.circleConversationDao.insert(item);
        }
        return null;
      case DbWriteMethod.deleteCircleConversationById:
        final payload =
            request.payload! as DbWriteDeleteCircleConversationPayload;
        await database.circleConversationDao.deleteById(
          payload.conversationId,
          payload.circleId,
        );
        return null;
      case DbWriteMethod.deleteCircleAndConversations:
        final circleId = request.payload! as String;
        await database.transaction(() async {
          await database.circleDao.deleteCircleById(circleId);
          await database.circleConversationDao.deleteByCircleId(circleId);
        });
        return null;
      case DbWriteMethod.upsertContactConversation:
        final payload =
            request.payload! as DbWriteUpsertContactConversationPayload;
        await database.transaction(() async {
          await database.conversationDao.insert(
            db.Conversation(
              conversationId: payload.conversationId,
              category: sdk.ConversationCategory.contact,
              createdAt: payload.createdAt,
              ownerId: payload.recipientId,
              status: sdk.ConversationStatus.start,
            ),
          );
          await database.participantDao.insert(
            db.Participant(
              conversationId: payload.conversationId,
              userId: payload.currentUserId,
              createdAt: payload.createdAt,
            ),
          );
          await database.participantDao.insert(
            db.Participant(
              conversationId: payload.conversationId,
              userId: payload.recipientId,
              createdAt: payload.createdAt,
            ),
          );
        });
        return null;
      case DbWriteMethod.updateUserMuteUntil:
        final payload = request.payload! as DbWriteUpdateUserMuteUntilPayload;
        await database.userDao.updateMuteUntil(
          payload.userId,
          payload.muteUntil,
        );
        return null;
      case DbWriteMethod.updateConversationMuteUntil:
        final payload =
            request.payload! as DbWriteUpdateConversationMuteUntilPayload;
        await database.conversationDao.updateMuteUntil(
          payload.conversationId,
          payload.muteUntil,
        );
        return null;
      case DbWriteMethod.updateConversationCodeUrl:
        final payload =
            request.payload! as DbWriteUpdateConversationCodeUrlPayload;
        await database.conversationDao.updateCodeUrl(
          payload.conversationId,
          payload.codeUrl,
        );
        return null;
      case DbWriteMethod.cleanupParticipantSession:
        final payload =
            request.payload! as DbWriteCleanupParticipantSessionPayload;
        await database.participantSessionDao.deleteBySessionId(
          payload.sessionId,
        );
        await database.participantSessionDao.updateSentToServer();
        return null;
      case DbWriteMethod.pinConversation:
        final conversationId = request.payload! as String;
        await database.conversationDao.pin(conversationId);
        return null;
      case DbWriteMethod.unpinConversation:
        final conversationId = request.payload! as String;
        await database.conversationDao.unpin(conversationId);
        return null;
      case DbWriteMethod.markMentionRead:
        final messageId = request.payload! as String;
        await database.messageMentionDao.markMentionRead(messageId);
        return null;
      case DbWriteMethod.parseMentionData:
        final payload = request.payload! as DbWriteParseMentionDataPayload;
        await database.messageMentionDao.parseMentionData(
          payload.content,
          payload.messageId,
          payload.conversationId,
          payload.senderId,
          payload.quoteContentJson == null
              ? null
              : mapToQuoteMessage(
                  jsonDecode(payload.quoteContentJson!) as Map<String, dynamic>,
                ),
          payload.currentUserId,
          payload.currentUserIdentityNumber,
        );
        return null;
      case DbWriteMethod.deleteFloodMessage:
        final floodMessage = request.payload! as db.FloodMessage;
        await database.floodMessageDao.deleteFloodMessage(floodMessage);
        return null;
      case DbWriteMethod.upsertOffset:
        final offset = request.payload! as db.Offset;
        await database.offsetDao.insert(offset);
        return null;
      case DbWriteMethod.updateMessageStatusById:
        final payload = request.payload! as DbWriteUpdateMessageStatusPayload;
        await database.messageDao.updateMessageStatusById(
          payload.messageId,
          payload.status,
        );
        return null;
      case DbWriteMethod.deleteExpiredMessageByMessageId:
        final messageId = request.payload! as String;
        await database.expiredMessageDao.deleteByMessageId(messageId);
        return null;
      case DbWriteMethod.insertExpiredMessage:
        final payload = request.payload! as DbWriteInsertExpiredMessagePayload;
        await database.expiredMessageDao.insert(
          messageId: payload.messageId,
          expireIn: payload.expireIn,
          expireAt: payload.expireAt,
        );
        return null;
      case DbWriteMethod.updateExpiredMessageExpireAt:
        final payload =
            request.payload! as DbWriteUpdateExpiredMessageExpireAtPayload;
        await database.expiredMessageDao.updateMessageExpireAt(
          payload.expireAt,
          payload.messageId,
        );
        return null;
      case DbWriteMethod.markMessagesRead:
        final payload = request.payload! as DbWriteMarkMessagesReadPayload;
        await database.messageDao.markMessageRead(
          payload.items
              .map(
                (item) => MiniMessageItem(
                  messageId: item.messageId,
                  conversationId: item.conversationId,
                ),
              )
              .toList(),
          updateExpired: false,
        );
        return null;
      case DbWriteMethod.markExpiredMessagesRead:
        final messageIds = (request.payload! as List<dynamic>).cast<String>();
        await database.expiredMessageDao.onMessageRead(messageIds);
        return null;
      case DbWriteMethod.takeConversationUnseen:
        final payload =
            request.payload! as DbWriteTakeConversationUnseenPayload;
        await database.messageDao.takeUnseen(
          payload.currentUserId,
          payload.conversationId,
        );
        return null;
      case DbWriteMethod.insertSendMessage:
        final payload = request.payload! as DbWriteInsertSendMessagePayload;
        await database.messageDao.insert(
          payload.message,
          payload.currentUserId,
          silent: payload.silent,
          expireIn: payload.expireIn,
          cleanDraft: payload.cleanDraft,
        );
        await database.ftsDatabase.insertFts(
          payload.message,
          payload.ftsContent,
        );
        return null;
      case DbWriteMethod.insertMessageHistory:
        final payload = request.payload! as DbWriteInsertMessageHistoryPayload;
        await database.messageHistoryDao.insert(
          db.MessagesHistoryData(messageId: payload.messageId),
        );
        return null;
      case DbWriteMethod.insertMessageHistoryBatch:
        final payload =
            request.payload! as DbWriteInsertMessageHistoryBatchPayload;
        if (payload.messageIds.isEmpty) return null;
        await database.messageHistoryDao.insertList(
          payload.messageIds.map(
            (id) => db.MessagesHistoryData(messageId: id),
          ),
        );
        return null;
      case DbWriteMethod.insertResendSessionMessage:
        final payload =
            request.payload! as DbWriteInsertResendSessionMessagePayload;
        await database.resendSessionMessageDao.insert(payload.message);
        return null;
      case DbWriteMethod.updateAttachmentMessageContentAndStatus:
        final payload =
            request.payload!
                as DbWriteUpdateAttachmentMessageContentAndStatusPayload;
        await database.messageDao.updateAttachmentMessageContentAndStatus(
          payload.messageId,
          payload.content,
          payload.key,
          payload.digest,
        );
        return null;
      case DbWriteMethod.updateMessageContentAndStatus:
        final payload =
            request.payload! as DbWriteUpdateMessageContentAndStatusPayload;
        await database.messageDao.updateMessageContentAndStatus(
          payload.messageId,
          payload.content,
          payload.status,
        );
        return null;
      case DbWriteMethod.updateMessageContent:
        final payload = request.payload! as DbWriteUpdateMessageContentPayload;
        await database.messageDao.updateMessageContent(
          payload.messageId,
          payload.content,
        );
        return null;
      case DbWriteMethod.updateMessageCategoryById:
        final payload = request.payload! as DbWriteUpdateMessageCategoryPayload;
        await database.messageDao.updateCategoryById(
          payload.messageId,
          payload.category,
        );
        return null;
      case DbWriteMethod.deleteResendSessionMessageById:
        final payload =
            request.payload! as DbWriteDeleteResendSessionMessagePayload;
        await database.resendSessionMessageDao.deleteResendSessionMessageById(
          payload.messageId,
        );
        return null;
      case DbWriteMethod.updateAttachmentMessage:
        final payload =
            request.payload! as DbWriteUpdateAttachmentMessagePayload;
        await database.messageDao.updateAttachmentMessage(
          payload.messageId,
          db.MessagesCompanion(
            status: Value(payload.status),
            content: Value(payload.content),
            mediaMimeType: Value(payload.mediaMimeType),
            mediaSize: Value(payload.mediaSize),
            mediaStatus: Value(payload.mediaStatus),
            mediaWidth: Value(payload.mediaWidth),
            mediaHeight: Value(payload.mediaHeight),
            mediaDigest: Value(payload.mediaDigest),
            mediaKey: Value(payload.mediaKey),
            mediaWaveform: Value(payload.mediaWaveform),
            caption: Value(payload.caption),
            name: Value(payload.name),
            thumbImage: Value(payload.thumbImage),
            mediaDuration: Value(payload.mediaDuration),
          ),
        );
        return null;
      case DbWriteMethod.updateStickerMessage:
        final payload = request.payload! as DbWriteUpdateStickerMessagePayload;
        await database.messageDao.updateStickerMessage(
          payload.messageId,
          payload.status,
          payload.stickerId,
        );
        return null;
      case DbWriteMethod.updateContactMessage:
        final payload = request.payload! as DbWriteUpdateContactMessagePayload;
        await database.messageDao.updateContactMessage(
          payload.messageId,
          payload.status,
          payload.sharedUserId,
        );
        return null;
      case DbWriteMethod.updateLiveMessage:
        final payload = request.payload! as DbWriteUpdateLiveMessagePayload;
        await database.messageDao.updateLiveMessage(
          payload.messageId,
          payload.width,
          payload.height,
          payload.url,
          payload.thumbUrl,
          payload.status,
        );
        return null;
      case DbWriteMethod.updateTranscriptMessage:
        final payload =
            request.payload! as DbWriteUpdateTranscriptMessagePayload;
        await database.messageDao.updateTranscriptMessage(
          payload.content,
          payload.mediaSize,
          payload.mediaStatus,
          payload.status,
          payload.messageId,
        );
        return null;
      case DbWriteMethod.deletePendingSafeSnapshotByHash:
        final payload =
            request.payload! as DbWriteDeletePendingSafeSnapshotByHashPayload;
        await database.safeSnapshotDao.deletePendingSnapshotByHash(
          payload.depositHash,
        );
        return null;
      case DbWriteMethod.recallMessage:
        final payload = request.payload! as DbWriteRecallMessagePayload;
        await database.messageDao.recallMessage(
          payload.conversationId,
          payload.messageId,
        );
        return null;
      case DbWriteMethod.deleteMessageMention:
        final payload = request.payload! as DbWriteDeleteMessageMentionPayload;
        await database.messageMentionDao.deleteMessageMention(
          payload.messageMention,
        );
        return null;
      case DbWriteMethod.updateQuoteContentByQuoteId:
        final payload =
            request.payload! as DbWriteUpdateQuoteContentByQuoteIdPayload;
        await database.messageDao.updateQuoteContentByQuoteId(
          payload.conversationId,
          payload.quoteMessageId,
          payload.content,
        );
        return null;
      case DbWriteMethod.insertTranscriptMessages:
        final payload =
            request.payload! as DbWriteInsertTranscriptMessagesPayload;
        await database.transcriptMessageDao.insertAll(payload.transcripts);
        return null;
      case DbWriteMethod.updateTranscript:
        final payload = request.payload! as DbWriteUpdateTranscriptPayload;
        await database.transcriptMessageDao.updateTranscript(
          transcriptId: payload.transcriptId,
          messageId: payload.messageId,
          attachmentId: payload.attachmentId,
          key: payload.key,
          digest: payload.digest,
          mediaStatus: payload.mediaStatus,
          mediaCreatedAt: payload.mediaCreatedAt,
          category: payload.category,
        );
        return null;
      case DbWriteMethod.updateMessageMediaStatus:
        final payload =
            request.payload! as DbWriteUpdateMessageMediaStatusPayload;
        await database.messageDao.updateMediaStatus(
          payload.messageId,
          payload.status,
        );
        return null;
      case DbWriteMethod.pinAndInsertPinMessages:
        final payload =
            request.payload! as DbWritePinAndInsertPinMessagesPayload;
        for (final pinMessage in payload.pinMessages) {
          await database.pinMessageDao.insert(pinMessage);
        }
        for (final message in payload.systemMessages) {
          await database.messageDao.insert(
            message,
            payload.currentUserId,
            cleanDraft: false,
          );
        }
        return null;
      case DbWriteMethod.deletePinMessagesByIds:
        final payload = request.payload! as DbWriteDeletePinMessagesPayload;
        await database.pinMessageDao.deleteByIds(payload.messageIds);
        return null;
      case DbWriteMethod.updateGiphyMessage:
        final payload = request.payload! as DbWriteUpdateGiphyMessagePayload;
        await database.messageDao.updateGiphyMessage(
          payload.messageId,
          payload.mediaUrl,
          payload.mediaSize,
          payload.thumbImage,
        );
        return null;
      case DbWriteMethod.insertFts:
        final payload = request.payload! as DbWriteInsertFtsPayload;
        await database.ftsDatabase.insertFts(
          payload.message,
          payload.content,
        );
        return null;
      case DbWriteMethod.deleteFtsByMessageId:
        final messageId = request.payload! as String;
        await database.ftsDatabase.deleteByMessageId(messageId);
        return null;
      case DbWriteMethod.deleteFtsByConversationId:
        final conversationId = request.payload! as String;
        await database.ftsDatabase.deleteByConversationId(conversationId);
        return null;
      case DbWriteMethod.deleteConversation:
        final conversationId = request.payload! as String;
        await database.conversationDao.deleteConversation(conversationId);
        return null;
      case DbWriteMethod.updateConversationDraft:
        final payload =
            request.payload! as DbWriteUpdateConversationDraftPayload;
        await database.conversationDao.updateDraft(
          payload.conversationId,
          payload.draft,
        );
        return null;
      case DbWriteMethod.updateCircleOrders:
        final payload = request.payload! as DbWriteUpdateCircleOrdersPayload;
        await database.circleDao.updateOrders(payload.items);
        return null;
      case DbWriteMethod.insertSticker:
        final sticker = request.payload! as db.StickersCompanion;
        await database.stickerDao.insert(sticker);
        return null;
      case DbWriteMethod.insertStickerAndRelationship:
        final payload =
            request.payload! as DbWriteInsertStickerAndRelationshipPayload;
        await database.transaction(() async {
          await database.stickerDao.insert(payload.sticker);
          await database.stickerRelationshipDao.insert(payload.relationship);
        });
        return null;
      case DbWriteMethod.deletePersonalSticker:
        final stickerId = request.payload! as String;
        await database.stickerDao.deletePersonalSticker(stickerId);
        return null;
      case DbWriteMethod.updateStickerUsedAt:
        final payload = request.payload! as DbWriteUpdateStickerUsedAtPayload;
        await database.stickerDao.updateUsedAt(
          payload.albumId,
          payload.stickerId,
          payload.usedAt,
        );
        return null;
      case DbWriteMethod.updateStickerAlbumAdded:
        final payload =
            request.payload! as DbWriteUpdateStickerAlbumAddedPayload;
        await database.stickerAlbumDao.updateAdded(
          payload.albumId,
          payload.added,
        );
        return null;
      case DbWriteMethod.updateStickerAlbumOrders:
        final payload =
            request.payload! as DbWriteUpdateStickerAlbumOrdersPayload;
        await database.stickerAlbumDao.updateOrders(payload.albums);
        return null;
      case DbWriteMethod.updateSafeSnapshotMessage:
        final payload =
            request.payload! as DbWriteUpdateSafeSnapshotMessagePayload;
        await database.messageDao.updateSafeSnapshotMessage(
          payload.messageId,
          payload.snapshotId,
        );
        return null;
      case DbWriteMethod.deleteMessage:
        final payload = request.payload! as DbWriteDeleteMessagePayload;
        await database.messageDao.deleteMessage(
          payload.conversationId,
          payload.messageId,
        );
        return null;
      case DbWriteMethod.deleteMessagesByConversation:
        final payload =
            request.payload! as DbWriteDeleteMessagesByConversationPayload;
        await database.messageDao.deleteMessagesByConversationId(
          payload.conversationId,
        );
        await database.messageMentionDao.clearMessageMentionByConversationId(
          payload.conversationId,
        );
        return null;
      case DbWriteMethod.upsertAssetAndChain:
        final payload = request.payload! as DbWriteUpsertAssetAndChainPayload;
        await Future.wait([
          database.assetDao.insertSdkAsset(payload.asset),
          database.chainDao.insertSdkChain(payload.chain),
        ]);
        return null;
      case DbWriteMethod.upsertTokenAndChain:
        final payload = request.payload! as DbWriteUpsertTokenAndChainPayload;
        await Future.wait([
          database.tokenDao.insertSdkToken(payload.token),
          database.chainDao.insertSdkChain(payload.chain),
        ]);
        return null;
      case DbWriteMethod.upsertSnapshot:
        final snapshot = request.payload!;
        if (snapshot is sdk.Snapshot) {
          await database.snapshotDao.insertSdkSnapshot(snapshot);
        } else if (snapshot is db.Snapshot) {
          await database.snapshotDao.insert(snapshot);
        } else {
          throw ArgumentError(
            'invalid snapshot payload type: ${snapshot.runtimeType}',
          );
        }
        return null;
      case DbWriteMethod.upsertSafeSnapshot:
        final snapshot = request.payload!;
        if (snapshot is sdk.SafeSnapshot) {
          await database.safeSnapshotDao.insertSdkSnapshot(snapshot);
        } else if (snapshot is db.SafeSnapshot) {
          await database.safeSnapshotDao.insert(snapshot);
        } else {
          throw ArgumentError(
            'invalid safe snapshot payload type: ${snapshot.runtimeType}',
          );
        }
        return null;
      case DbWriteMethod.replaceFiats:
        final fiats = (request.payload! as List<dynamic>).cast<sdk.Fiat>();
        await database.fiatDao.insertAllSdkFiat(fiats);
        return null;
      case DbWriteMethod.insertFavoriteApps:
        final payload = request.payload! as DbWriteFavoriteAppsPayload;
        await database.favoriteAppDao.insertFavoriteApps(
          payload.userId,
          payload.apps,
        );
        return null;
      case DbWriteMethod.upsertStickerAlbum:
        final stickerAlbum = request.payload! as db.StickerAlbumsCompanion;
        await database.stickerAlbumDao.insert(stickerAlbum);
        return null;
      case DbWriteMethod.replaceStickersByAlbum:
        final payload =
            request.payload! as DbWriteReplaceStickersByAlbumPayload;
        await database.transaction(() async {
          await database.stickerRelationshipDao.insertAll(
            payload.relationships,
          );
          await database.stickerDao.insertAll(payload.stickers);
        });
        return null;
      case DbWriteMethod.insertFloodMessage:
        final floodMessage = request.payload! as db.FloodMessage;
        await database.floodMessageDao.insert(floodMessage);
        return null;
      case DbWriteMethod.deleteLegacyFtsChunk:
        await database.mixinDatabase.customStatement(
          'DELETE FROM messages_fts WHERE rowid IN (SELECT rowid FROM messages_fts LIMIT 1000)',
        );
        return null;
      case DbWriteMethod.migrateFtsInsertBatch:
        final payload = request.payload! as DbWriteMigrateFtsInsertBatchPayload;
        final messageMeta = <int, db.Message>{};
        for (final message in payload.messages) {
          final exists = await database.ftsDatabase
              .checkMessageMetaExists(message.messageId)
              .getSingle();
          if (exists) {
            continue;
          }
          final rowId = await database.ftsDatabase.insertFtsOnly(
            message,
            payload.transcriptContentMap[message.messageId],
          );
          if (rowId != null) {
            messageMeta[rowId] = message;
          }
        }
        if (messageMeta.isNotEmpty) {
          await database.ftsDatabase.batch((batch) {
            batch.insertAll(database.ftsDatabase.messagesMetas, [
              for (final entry in messageMeta.entries)
                MessagesMeta(
                  docId: entry.key,
                  messageId: entry.value.messageId,
                  conversationId: entry.value.conversationId,
                  category: entry.value.category,
                  userId: entry.value.userId,
                  createdAt: entry.value.createdAt,
                ),
            ]);
          });
        }
        return null;
      case DbWriteMethod.replaceMigrateFtsJob:
        final payload = request.payload! as DbWriteReplaceMigrateFtsJobPayload;
        await database.jobDao.transaction(() async {
          await database.jobDao.deleteJobByAction(kMigrateFts);
          await database.jobDao.insert(
            createMigrationFtsJob(payload.messageRowId),
          );
        });
        return null;
      case DbWriteMethod.insertCleanupQuoteContentJob:
        await database.jobDao.insert(createCleanupQuoteContentJob());
        return null;
    }
  }

  Future<void> _insertUpdateUsers(List<sdk.User> users) async {
    if (users.isEmpty) return;
    await database.userDao.insertAllSdkUser(users);

    for (final user in users) {
      final app = user.app;
      if (app == null) continue;
      await database.appDao.insert(
        db.App(
          appId: app.appId,
          appNumber: app.appNumber,
          homeUri: app.homeUri,
          redirectUri: app.redirectUri,
          name: app.name,
          iconUrl: app.iconUrl,
          category: app.category,
          description: app.description,
          appSecret: app.category,
          capabilities: app.capabilites?.toString(),
          creatorId: app.creatorId,
          resourcePatterns: app.resourcePatterns?.toString(),
          updatedAt: app.updatedAt,
        ),
      );
    }
  }

  Future<void> dispose() async {
    _patchBatcher.dispose();
    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    _subscriptions.clear();
    await database.dispose();
  }
}
