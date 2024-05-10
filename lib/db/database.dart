import 'dart:async';

import '../ui/provider/slide_category_provider.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';
import '../utils/property/setting_property.dart';
import 'dao/app_dao.dart';
import 'dao/asset_dao.dart';
import 'dao/chain_dao.dart';
import 'dao/circle_conversation_dao.dart';
import 'dao/circle_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/expired_message_dao.dart';
import 'dao/favorite_app_dao.dart';
import 'dao/fiat_dao.dart';
import 'dao/flood_message_dao.dart';
import 'dao/inscription_collection_dao.dart';
import 'dao/inscription_item_dao.dart';
import 'dao/job_dao.dart';
import 'dao/message_dao.dart';
import 'dao/message_history_dao.dart';
import 'dao/message_mention_dao.dart';
import 'dao/offset_dao.dart';
import 'dao/participant_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/pin_message_dao.dart';
import 'dao/resend_session_message_dao.dart';
import 'dao/safe_snapshot_dao.dart';
import 'dao/snapshot_dao.dart';
import 'dao/sticker_album_dao.dart';
import 'dao/sticker_dao.dart';
import 'dao/sticker_relationship_dao.dart';
import 'dao/token_dao.dart';
import 'dao/transcript_message_dao.dart';
import 'dao/user_dao.dart';
import 'fts_database.dart';
import 'mixin_database.dart';

class Database {
  Database(this.mixinDatabase, this.ftsDatabase) {
    settingProperties = SettingPropertyStorage(mixinDatabase.propertyDao);
  }

  final MixinDatabase mixinDatabase;

  final FtsDatabase ftsDatabase;

  AppDao get appDao => mixinDatabase.appDao;

  AssetDao get assetDao => mixinDatabase.assetDao;

  ChainDao get chainDao => mixinDatabase.chainDao;

  TokenDao get tokenDao => mixinDatabase.tokenDao;

  MessageDao get messageDao => mixinDatabase.messageDao;

  MessageHistoryDao get messageHistoryDao => mixinDatabase.messageHistoryDao;

  MessageMentionDao get messageMentionDao => mixinDatabase.messageMentionDao;

  ConversationDao get conversationDao => mixinDatabase.conversationDao;

  CircleDao get circleDao => mixinDatabase.circleDao;

  CircleConversationDao get circleConversationDao =>
      mixinDatabase.circleConversationDao;

  FloodMessageDao get floodMessageDao => mixinDatabase.floodMessageDao;

  JobDao get jobDao => mixinDatabase.jobDao;

  OffsetDao get offsetDao => mixinDatabase.offsetDao;

  ParticipantDao get participantDao => mixinDatabase.participantDao;

  ParticipantSessionDao get participantSessionDao =>
      mixinDatabase.participantSessionDao;

  ResendSessionMessageDao get resendSessionMessageDao =>
      mixinDatabase.resendSessionMessageDao;

  SnapshotDao get snapshotDao => mixinDatabase.snapshotDao;

  SafeSnapshotDao get safeSnapshotDao => mixinDatabase.safeSnapshotDao;

  StickerDao get stickerDao => mixinDatabase.stickerDao;

  StickerAlbumDao get stickerAlbumDao => mixinDatabase.stickerAlbumDao;

  StickerRelationshipDao get stickerRelationshipDao =>
      mixinDatabase.stickerRelationshipDao;

  UserDao get userDao => mixinDatabase.userDao;

  TranscriptMessageDao get transcriptMessageDao =>
      mixinDatabase.transcriptMessageDao;

  PinMessageDao get pinMessageDao => mixinDatabase.pinMessageDao;

  FiatDao get fiatDao => mixinDatabase.fiatDao;

  FavoriteAppDao get favoriteAppDao => mixinDatabase.favoriteAppDao;

  ExpiredMessageDao get expiredMessageDao => mixinDatabase.expiredMessageDao;

  InscriptionCollectionDao get inscriptionCollectionDao =>
      mixinDatabase.inscriptionCollectionDao;

  InscriptionItemDao get inscriptionItemDao => mixinDatabase.inscriptionItemDao;

  late final SettingPropertyStorage settingProperties;

  Future<void> dispose() async {
    await mixinDatabase.close();
    await ftsDatabase.close();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }

  Future<T> transaction<T>(Future<T> Function() action) =>
      mixinDatabase.transaction<T>(action);

  /// [conversationIds] empty to search all conversations.
  Future<List<SearchMessageDetailItem>> fuzzySearchMessage({
    required String query,
    required int limit,
    List<String> conversationIds = const [],
    String? userId,
    List<String>? categories,
    String? anchorMessageId,
  }) async {
    final messageIds = await ftsDatabase.fuzzySearchMessage(
      query: query,
      limit: limit,
      conversationIds: conversationIds,
      userId: userId,
      categories: categories,
      anchorMessageId: anchorMessageId,
    );
    final messages =
        await mixinDatabase.messageDao.searchMessageByIds(messageIds).get();

    final result = <SearchMessageDetailItem>[];

    for (final messageId in messageIds) {
      final message =
          messages.firstWhereOrNull((m) => m.messageId == messageId);
      if (message != null) {
        result.add(message);
      } else {
        e('fuzzySearchMessage message not found $messageId');
        unawaited(ftsDatabase.deleteByMessageId(messageId));
      }
    }
    return messages;
  }

  Future<List<SearchMessageDetailItem>> fuzzySearchMessageByCategory(
    String keyword, {
    required int limit,
    required SlideCategoryState category,
    bool unseenConversationOnly = false,
    String? anchorMessageId,
  }) async {
    Future<List<String>> getConversationIds() async {
      final List<String> conversations;
      if (unseenConversationOnly) {
        conversations = await conversationDao
            .unseenConversationByCategory(category.type)
            .map((item) => item.conversationId)
            .get();
      } else {
        conversations = await conversationDao
            .conversationItemsByCategory(category.type, 1000, 0)
            .get()
            .then((value) => value.map((e) => e.conversationId).toList());
      }
      return conversations;
    }

    switch (category.type) {
      case SlideCategoryType.chats:
        if (!unseenConversationOnly) {
          return fuzzySearchMessage(
            query: keyword,
            limit: limit,
            anchorMessageId: anchorMessageId,
          );
        }
        final conversationIds = await getConversationIds();
        if (conversationIds.isEmpty) {
          i('fuzzySearchMessageByCategory $category $unseenConversationOnly no conversationIds');
          return Future.value(const []);
        }
        return fuzzySearchMessage(
          query: keyword,
          limit: limit,
          anchorMessageId: anchorMessageId,
          conversationIds: conversationIds,
        );
      case SlideCategoryType.groups:
      case SlideCategoryType.bots:
      case SlideCategoryType.strangers:
      case SlideCategoryType.contacts:
        final conversationIds = await getConversationIds();
        if (conversationIds.isEmpty) {
          i('fuzzySearchMessageByCategory $category $unseenConversationOnly no conversationIds');
          return Future.value(const []);
        }
        return fuzzySearchMessage(
          query: keyword,
          limit: limit,
          anchorMessageId: anchorMessageId,
          conversationIds: await getConversationIds(),
        );
      case SlideCategoryType.circle:
        final circleId = category.id!;
        final List<String> conversationIds;
        if (unseenConversationOnly) {
          conversationIds = await conversationDao
              .unseenConversationsByCircleId(circleId)
              .map((item) => item.conversationId)
              .get();
        } else {
          conversationIds = await conversationDao
              .conversationsByCircleId(circleId, 1000, 0)
              .map((item) => item.conversationId)
              .get();
        }
        if (conversationIds.isEmpty) {
          i('fuzzySearchMessageByCategory $category $unseenConversationOnly no conversationIds');
          return Future.value(const []);
        }
        return fuzzySearchMessage(
          query: keyword,
          limit: limit,
          anchorMessageId: anchorMessageId,
          conversationIds: conversationIds,
        );
      case SlideCategoryType.setting:
        assert(false, 'should not search setting');
        return Future.value(const []);
    }
  }
}
