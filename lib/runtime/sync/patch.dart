import '../../db/dao/job_dao.dart';
import '../../db/dao/message_dao.dart';
import '../../db/dao/participant_dao.dart';
import '../../db/event.dart';

enum SyncPatchType {
  notification,
  insertOrReplaceMessage,
  deleteMessage,
  updateExpiredMessage,
  updateConversation,
  updateFavoriteApp,
  updateUser,
  updateParticipant,
  updateSticker,
  updateSnapshot,
  updateMessageMention,
  updateCircle,
  updateCircleConversation,
  updatePinMessage,
  updateTranscriptMessage,
  updateAsset,
  updateToken,
  addJob,
}

class SyncPatch {
  const SyncPatch(this.type, [this.payload]);

  factory SyncPatch.notification(MiniNotificationMessage message) =>
      SyncPatch(SyncPatchType.notification, message);

  factory SyncPatch.insertOrReplaceMessage(List<MiniMessageItem> events) =>
      SyncPatch(SyncPatchType.insertOrReplaceMessage, events);

  factory SyncPatch.deleteMessage(List<String> messageIds) =>
      SyncPatch(SyncPatchType.deleteMessage, messageIds);

  factory SyncPatch.updateExpiredMessage() =>
      const SyncPatch(SyncPatchType.updateExpiredMessage);

  factory SyncPatch.updateConversation(List<String> conversationIds) =>
      SyncPatch(SyncPatchType.updateConversation, conversationIds);

  factory SyncPatch.updateFavoriteApp(List<String> appIds) =>
      SyncPatch(SyncPatchType.updateFavoriteApp, appIds);

  factory SyncPatch.updateUser(List<String> userIds) =>
      SyncPatch(SyncPatchType.updateUser, userIds);

  factory SyncPatch.updateParticipant(List<MiniParticipantItem> participants) =>
      SyncPatch(SyncPatchType.updateParticipant, participants);

  factory SyncPatch.updateSticker(List<MiniSticker> stickers) =>
      SyncPatch(SyncPatchType.updateSticker, stickers);

  factory SyncPatch.updateSnapshot(List<String> snapshotIds) =>
      SyncPatch(SyncPatchType.updateSnapshot, snapshotIds);

  factory SyncPatch.updateMessageMention(List<MiniMessageItem> events) =>
      SyncPatch(SyncPatchType.updateMessageMention, events);

  factory SyncPatch.updateCircle() =>
      const SyncPatch(SyncPatchType.updateCircle);

  factory SyncPatch.updateCircleConversation() =>
      const SyncPatch(SyncPatchType.updateCircleConversation);

  factory SyncPatch.updatePinMessage(List<MiniMessageItem> events) =>
      SyncPatch(SyncPatchType.updatePinMessage, events);

  factory SyncPatch.updateTranscriptMessage(
    List<MiniTranscriptMessage> events,
  ) => SyncPatch(SyncPatchType.updateTranscriptMessage, events);

  factory SyncPatch.updateAsset(List<String> assetIds) =>
      SyncPatch(SyncPatchType.updateAsset, assetIds);

  factory SyncPatch.updateToken(List<String> tokenIds) =>
      SyncPatch(SyncPatchType.updateToken, tokenIds);

  factory SyncPatch.addJob(MiniJobItem job) =>
      SyncPatch(SyncPatchType.addJob, job);

  final SyncPatchType type;
  final Object? payload;
}
