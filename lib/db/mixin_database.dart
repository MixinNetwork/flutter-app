import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../constants/constants.dart';
import '../enum/media_status.dart';
import '../enum/property_group.dart';
import 'converter/conversation_category_type_converter.dart';
import 'converter/conversation_status_type_converter.dart';
import 'converter/media_status_type_converter.dart';
import 'converter/membership_converter.dart';
import 'converter/message_status_type_converter.dart';
import 'converter/millis_date_converter.dart';
import 'converter/participant_role_converter.dart';
import 'converter/property_group_converter.dart';
import 'converter/safe_deposit_type_converter.dart';
import 'converter/safe_withdrawal_type_converter.dart';
import 'converter/user_relationship_converter.dart';
import 'dao/address_dao.dart';
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
import 'dao/hyperlink_dao.dart';
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
import 'dao/property_dao.dart';
import 'dao/resend_session_message_dao.dart';
import 'dao/safe_snapshot_dao.dart';
import 'dao/sent_session_sender_key_dao.dart';
import 'dao/snapshot_dao.dart';
import 'dao/sticker_album_dao.dart';
import 'dao/sticker_dao.dart';
import 'dao/sticker_relationship_dao.dart';
import 'dao/token_dao.dart';
import 'dao/transcript_message_dao.dart';
import 'dao/user_dao.dart';
import 'database_event_bus.dart';
import 'extension/job.dart';
import 'util/open_database.dart';
import 'util/util.dart';

part 'mixin_database.g.dart';

@DriftDatabase(
  include: {'moor/mixin.drift', 'moor/dao/common.drift'},
  daos: [
    AddressDao,
    AppDao,
    AssetDao,
    CircleConversationDao,
    CircleDao,
    ConversationDao,
    FloodMessageDao,
    HyperlinkDao,
    JobDao,
    MessageMentionDao,
    MessageDao,
    MessageHistoryDao,
    OffsetDao,
    ParticipantDao,
    ParticipantSessionDao,
    ResendSessionMessageDao,
    SentSessionSenderKeyDao,
    SnapshotDao,
    StickerDao,
    StickerAlbumDao,
    StickerRelationshipDao,
    UserDao,
    PinMessageDao,
    FiatDao,
    FavoriteAppDao,
    ExpiredMessageDao,
    ChainDao,
    PropertyDao,
    TranscriptMessageDao,
    SafeSnapshotDao,
    TokenDao,
    InscriptionItemDao,
    InscriptionCollectionDao,
  ],
)
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase(super.e);

  @override
  int get schemaVersion => 28;

  final eventBus = DataBaseEventBus.instance;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from <= 2) {
        await m.drop(
          Index('index_conversations_category_status_pin_time_created_at', ''),
        );
        await m.drop(Index('index_participants_conversation_id', ''));
        await m.drop(Index('index_participants_created_at', ''));
        await m.drop(Index('index_users_full_name', ''));
        await m.drop(Index('index_snapshots_asset_id', ''));
        await m.drop(
          Index('index_messages_conversation_id_user_id_status_created_at', ''),
        );
        await m.drop(
          Index('index_messages_conversation_id_status_user_id', ''),
        );
        await m.drop(
          Index('index_conversations_pin_time_last_message_created_at', ''),
        );
        await m.drop(Index('index_messages_conversation_id_category', ''));
        await m.drop(
          Index('index_messages_conversation_id_quote_message_id', ''),
        );
        await m.drop(
          Index('index_messages_conversation_id_status_user_id_created_at', ''),
        );
        await m.drop(Index('index_messages_conversation_id_created_at', ''));
        await m.drop(Index('index_message_mentions_conversation_id', ''));
        await m.drop(Index('index_users_relationship_full_name', ''));
        await m.drop(Index('index_messages_conversation_id', ''));

        await m.createIndex(indexConversationsCategoryStatus);
        await m.createIndex(indexConversationsMuteUntil);
        await m.createIndex(indexFloodMessagesCreatedAt);
        await m.createIndex(indexMessageMentionsConversationIdHasRead);
        await m.createIndex(indexMessagesConversationIdCreatedAt);
        await m.createIndex(indexParticipantsConversationIdCreatedAt);
        await m.createIndex(indexStickerAlbumsCategoryCreatedAt);
      }
      if (from <= 3) {
        await m.drop(addresses);
        await m.createTable(addresses);
        if (!await _checkColumnExists(
          assets.actualTableName,
          assets.reserve.name,
        )) {
          await m.addColumn(assets, assets.reserve);
        }
        if (!await _checkColumnExists(
          messages.actualTableName,
          messages.caption.name,
        )) {
          await m.addColumn(messages, messages.caption);
        }
      }
      if (from <= 4) {
        await m.createTable(transcriptMessages);
      }
      if (from <= 5) {
        await m.createTable(pinMessages);
        await m.createIndex(indexPinMessagesConversationId);
      }
      if (from <= 6) {
        await m.createTable(fiats);
      }
      if (from <= 7) {
        await m.drop(Trigger('', 'conversation_last_message_update'));
      }
      if (from <= 8) {
        await m.createIndex(indexMessageConversationIdStatusUserId);
      }
      if (from <= 9) {
        if (!await _checkColumnExists(
          stickerAlbums.actualTableName,
          stickerAlbums.orderedAt.name,
        )) {
          await m.addColumn(stickerAlbums, stickerAlbums.orderedAt);
        }
        if (!await _checkColumnExists(
          stickerAlbums.actualTableName,
          stickerAlbums.banner.name,
        )) {
          await m.addColumn(stickerAlbums, stickerAlbums.banner);
        }
        if (!await _checkColumnExists(
          stickerAlbums.actualTableName,
          stickerAlbums.added.name,
        )) {
          await m.addColumn(stickerAlbums, stickerAlbums.added);
        }
        await update(
          stickerAlbums,
        ).write(const StickerAlbumsCompanion(added: Value(true)));
      }
      if (from <= 10) {
        await m.createTable(favoriteApps);
      }
      if (from <= 11) {
        if (!await _checkColumnExists(
          snapshots.actualTableName,
          snapshots.traceId.name,
        )) {
          await m.addColumn(snapshots, snapshots.traceId);
        }
      }
      if (from <= 12) {
        if (!await _checkColumnExists(
          stickerAlbums.actualTableName,
          stickerAlbums.isVerified.name,
        )) {
          await m.addColumn(stickerAlbums, stickerAlbums.isVerified);
        }
      }
      if (from <= 13) {
        if (!await _checkColumnExists(
          conversations.actualTableName,
          conversations.expireIn.name,
        )) {
          await m.addColumn(conversations, conversations.expireIn);
        }
        await m.createTable(expiredMessages);
      }
      if (from <= 14) {
        await m.createIndex(indexMessagesConversationIdCategoryCreatedAt);
      }
      if (from <= 15) {
        await m.createIndex(indexUsersIdentityNumber);
      }
      if (from <= 16) {
        await _addColumnIfNotExists(m, users, users.codeUrl);
        await _addColumnIfNotExists(m, users, users.codeId);
      }
      if (from <= 17) {
        await m.createIndex(indexMessagesConversationIdQuoteMessageId);
      }
      if (from <= 18) {
        await m.createTable(chains);
      }
      if (from <= 19) {
        await m.drop(Trigger('', 'conversation_last_message_delete'));
      }
      if (from <= 21) {
        await _addColumnIfNotExists(m, snapshots, snapshots.snapshotHash);
        await _addColumnIfNotExists(m, snapshots, snapshots.openingBalance);
        await _addColumnIfNotExists(m, snapshots, snapshots.closingBalance);
      }
      if (from <= 22) {
        await m.createTable(properties);
      }
      if (from <= 23) {
        await _addColumnIfNotExists(m, users, users.isDeactivated);
      }
      if (from <= 24) {
        await m.createTable(safeSnapshots);
        await m.createTable(tokens);
        await m.createIndex(indexTokensKernelAssetId);
      }
      if (from <= 25) {
        await _addColumnIfNotExists(
          m,
          safeSnapshots,
          safeSnapshots.inscriptionHash,
        );
        await _addColumnIfNotExists(m, tokens, tokens.collectionHash);
        await m.createIndex(indexTokensCollectionHash);
        await m.createTable(inscriptionCollections);
        await m.createTable(inscriptionItems);
      }
      if (from <= 26) {
        await _addColumnIfNotExists(m, users, users.membership);
      }
      if (from <= 27) {
        await _addColumnIfNotExists(m, tokens, tokens.precision);
      }
    },
    beforeOpen: (details) async {
      if (details.hadUpgrade && details.versionBefore! <= 20) {
        await jobDao.insert(createMigrationFtsJob(null));
      }
    },
  );

  Future<void> _addColumnIfNotExists(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    if (!await _checkColumnExists(table.actualTableName, column.name)) {
      await m.addColumn(table, column);
    }
  }

  Future<bool> _checkColumnExists(String tableName, String columnName) async {
    final queryRow = await customSelect(
      "SELECT COUNT(*) AS CNTREC FROM pragma_table_info('$tableName') WHERE name='$columnName'",
    ).getSingle();
    return queryRow.read<bool>('CNTREC');
  }

  Future<bool> hasData<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table, [
    List<Join> joins = const [],
    Expression<bool> predicate = ignoreWhere,
  ]) async =>
      (await (selectOnly(table)
                ..addColumns([const CustomExpression<String>('1')])
                ..join(joins)
                ..where(predicate)
                ..limit(1))
              .get())
          .isNotEmpty;
}

/// Connect to the database.
Future<MixinDatabase> connectToDatabase(
  String identityNumber, {
  int readCount = 8,
  bool fromMainIsolate = false,
}) async {
  final queryExecutor = await openQueryExecutor(
    identityNumber: identityNumber,
    dbName: kDbFileName,
    readCount: readCount,
    fromMainIsolate: fromMainIsolate,
  );
  return MixinDatabase(queryExecutor);
}
