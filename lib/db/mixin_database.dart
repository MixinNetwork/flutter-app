import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:path/path.dart' as p;

import '../enum/media_status.dart';
import '../enum/message_action.dart';
import '../utils/file.dart';
import 'converter/conversation_category_type_converter.dart';
import 'converter/conversation_status_type_converter.dart';
import 'converter/media_status_type_converter.dart';
import 'converter/message_action_converter.dart';
import 'converter/message_status_type_converter.dart';
import 'converter/millis_date_converter.dart';
import 'converter/participant_role_converter.dart';
import 'converter/user_relationship_converter.dart';
import 'custom_vm_database_wrapper.dart';
import 'dao/address_dao.dart';
import 'dao/app_dao.dart';
import 'dao/asset_dao.dart';
import 'dao/circle_conversation_dao.dart';
import 'dao/circle_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/favorite_app_dao.dart';
import 'dao/fiat_dao.dart';
import 'dao/flood_message_dao.dart';
import 'dao/hyperlink_dao.dart';
import 'dao/job_dao.dart';
import 'dao/message_dao.dart';
import 'dao/message_history_dao.dart';
import 'dao/message_mention_dao.dart';
import 'dao/offset_dao.dart';
import 'dao/participant_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/pin_message_dao.dart';
import 'dao/resend_session_message_dao.dart';
import 'dao/sent_session_sender_key_dao.dart';
import 'dao/snapshot_dao.dart';
import 'dao/sticker_album_dao.dart';
import 'dao/sticker_dao.dart';
import 'dao/sticker_relationship_dao.dart';
import 'dao/user_dao.dart';
import 'database_event_bus.dart';
import 'util/util.dart';

part 'mixin_database.g.dart';

@DriftDatabase(
  include: {
    'moor/mixin.drift',
    'moor/dao/conversation.drift',
    'moor/dao/message.drift',
    'moor/dao/participant.drift',
    'moor/dao/sticker.drift',
    'moor/dao/sticker_album.drift',
    'moor/dao/user.drift',
    'moor/dao/circle.drift',
    'moor/dao/flood.drift',
    'moor/dao/pin_message.drift',
    'moor/dao/sticker_relationship.drift',
    'moor/dao/favorite_app.drift',
  },
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
  ],
  queries: {},
)
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase.connect(DatabaseConnection c) : super.connect(c);

  @override
  int get schemaVersion => 13;

  final eventBus = DataBaseEventBus();

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (_) async {
          if (executor.dialect == SqlDialect.sqlite) {
            await customStatement('PRAGMA journal_mode=WAL');
            await customStatement('PRAGMA foreign_keys=ON');
          }
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from <= 2) {
            await m.drop(Index(
                'index_conversations_category_status_pin_time_created_at', ''));
            await m.drop(Index('index_participants_conversation_id', ''));
            await m.drop(Index('index_participants_created_at', ''));
            await m.drop(Index('index_users_full_name', ''));
            await m.drop(Index('index_snapshots_asset_id', ''));
            await m.drop(Index(
                'index_messages_conversation_id_user_id_status_created_at',
                ''));
            await m.drop(
                Index('index_messages_conversation_id_status_user_id', ''));
            await m.drop(Index(
                'index_conversations_pin_time_last_message_created_at', ''));
            await m.drop(Index('index_messages_conversation_id_category', ''));
            await m.drop(
                Index('index_messages_conversation_id_quote_message_id', ''));
            await m.drop(Index(
                'index_messages_conversation_id_status_user_id_created_at',
                ''));
            await m
                .drop(Index('index_messages_conversation_id_created_at', ''));
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
                assets.actualTableName, assets.reserve.name)) {
              await m.addColumn(assets, assets.reserve);
            }
            if (!await _checkColumnExists(
                messages.actualTableName, messages.caption.name)) {
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
                stickerAlbums.actualTableName, stickerAlbums.orderedAt.name)) {
              await m.addColumn(stickerAlbums, stickerAlbums.orderedAt);
            }
            if (!await _checkColumnExists(
                stickerAlbums.actualTableName, stickerAlbums.banner.name)) {
              await m.addColumn(stickerAlbums, stickerAlbums.banner);
            }
            if (!await _checkColumnExists(
                stickerAlbums.actualTableName, stickerAlbums.added.name)) {
              await m.addColumn(stickerAlbums, stickerAlbums.added);
            }
            await update(stickerAlbums)
                .write(const StickerAlbumsCompanion(added: Value(true)));
          }
          if (from <= 10) {
            await m.createTable(favoriteApps);
          }
          if (from <= 11) {
            if (!await _checkColumnExists(
                snapshots.actualTableName, snapshots.traceId.name)) {
              await m.addColumn(snapshots, snapshots.traceId);
            }
          }
          if (from <= 12) {
            if (!await _checkColumnExists(
                stickerAlbums.actualTableName, stickerAlbums.isVerified.name)) {
              await m.addColumn(stickerAlbums, stickerAlbums.isVerified);
            }
          }
        },
      );

  Future<bool> _checkColumnExists(String tableName, String columnName) async {
    final queryRow = await customSelect(
            "SELECT COUNT(*) AS CNTREC FROM pragma_table_info('$tableName') WHERE name='$columnName'")
        .getSingle();
    return queryRow.read<bool>('CNTREC');
  }

  Stream<bool> watchHasData<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table, [
    List<Join> joins = const [],
    Expression<bool?> predicate = ignoreWhere,
  ]) =>
      (selectOnly(table)
            ..addColumns([const CustomExpression<String>('1')])
            ..join(joins)
            ..where(predicate)
            ..limit(1))
          .watch()
          .map((event) => event.isNotEmpty);

  Future<bool> hasData<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table, [
    List<Join> joins = const [],
    Expression<bool?> predicate = ignoreWhere,
  ]) async =>
      (await (selectOnly(table)
                ..addColumns([const CustomExpression<String>('1')])
                ..join(joins)
                ..where(predicate)
                ..limit(1))
              .get())
          .isNotEmpty;
}

LazyDatabase _openConnection(File dbFile) => LazyDatabase(() {
      final vmDatabase = NativeDatabase(dbFile);
      if (!kDebugMode) {
        return vmDatabase;
      }
      return CustomVmDatabaseWrapper(vmDatabase, logStatements: true);
    });

/// Connect to the database.
Future<MixinDatabase> connectToDatabase(
  String identityNumber, {
  bool fromMainIsolate = false,
}) async {
  final backgroundPortName = 'one_mixin_drift_background_$identityNumber';
  final foregroundPortName = 'one_mixin_drift_foreground_$identityNumber';

  final connects = await Future.wait([
    _crateIsolate(
      identityNumber,
      backgroundPortName,
      fromMainIsolate: fromMainIsolate,
    ),
    _crateIsolate(
      identityNumber,
      foregroundPortName,
      fromMainIsolate: fromMainIsolate,
    ),
  ].map((e) => e.then((e) => e.connect())));

  final background = connects[0];
  final foreground = connects[1];

  final connect = background.withExecutor(MultiExecutor(
    read: foreground.executor,
    write: background.executor,
  ));
  return MixinDatabase.connect(connect);
}

Future<DriftIsolate> _crateIsolate(
  String identityNumber,
  String name, {
  bool fromMainIsolate = false,
}) async {
  if (fromMainIsolate) {
    // Remove port if it exists. to avoid port leak on hot reload.
    IsolateNameServer.removePortNameMapping(name);
  }

  final existingIsolate = IsolateNameServer.lookupPortByName(name);

  if (existingIsolate == null) {
    final dbFile =
        File(p.join(mixinDocumentsDirectory.path, identityNumber, 'mixin.db'));
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _startBackground,
      _IsolateStartRequest(receivePort.sendPort, dbFile),
    );
    final isolate = await receivePort.first as DriftIsolate;
    IsolateNameServer.registerPortWithName(isolate.connectPort, name);
    return isolate;
  } else {
    return DriftIsolate.fromConnectPort(existingIsolate, serialize: false);
  }
}

void _startBackground(_IsolateStartRequest request) {
  final executor = _openConnection(request.dbFile);
  final moorIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  request.sendMoorIsolate.send(moorIsolate);
}

class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.dbFile);

  final SendPort sendMoorIsolate;
  final File dbFile;
}
