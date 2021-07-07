import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;

import '../enum/media_status.dart';
import '../enum/message_action.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../utils/file.dart';
import 'converter/conversation_category_type_converter.dart';
import 'converter/conversation_status_type_converter.dart';
import 'converter/media_status_type_converter.dart';
import 'converter/message_action_converter.dart';
import 'converter/message_category_type_converter.dart';
import 'converter/message_status_type_converter.dart';
import 'converter/millis_date_converter.dart';
import 'converter/participant_role_converter.dart';
import 'converter/user_relationship_converter.dart';
import 'dao/address_dao.dart';
import 'dao/app_dao.dart';
import 'dao/asset_dao.dart';
import 'dao/circle_conversation_dao.dart';
import 'dao/circle_dao.dart';
import 'dao/conversation_dao.dart';
import 'dao/flood_message_dao.dart';
import 'dao/hyperlink_dao.dart';
import 'dao/job_dao.dart';
import 'dao/message_dao.dart';
import 'dao/message_history_dao.dart';
import 'dao/message_mention_dao.dart';
import 'dao/offset_dao.dart';
import 'dao/participant_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/resend_session_message_dao.dart';
import 'dao/sent_session_sender_key_dao.dart';
import 'dao/snapshot_dao.dart';
import 'dao/sticker_album_dao.dart';
import 'dao/sticker_dao.dart';
import 'dao/sticker_relationship_dao.dart';
import 'dao/user_dao.dart';
import 'database_event_bus.dart';

part 'mixin_database.g.dart';

@UseMoor(
  include: {
    'moor/mixin.moor',
    'moor/dao/conversation.moor',
    'moor/dao/message.moor',
    'moor/dao/participant.moor',
    'moor/dao/sticker.moor',
    'moor/dao/sticker_album.moor',
    'moor/dao/user.moor',
    'moor/dao/circle.moor',
    'moor/dao/flood.moor',
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
  ],
  queries: {},
)
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase.connect(DatabaseConnection c) : super.connect(c);

  @override
  int get schemaVersion => 2;

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
          if (from == 1) {
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

            await m.createIndex(indexConversationsPinTimeLastMessageCreatedAt);
            await m.createIndex(indexMessagesConversationIdCategory);
            await m.createIndex(indexMessagesConversationIdQuoteMessageId);
            await m
                .createIndex(indexMessagesConversationIdStatusUserIdCreatedAt);
          }
        },
      );
}

LazyDatabase _openConnection(File dbFile) =>
    LazyDatabase(() => VmDatabase(dbFile));

Future<MixinDatabase> createMoorIsolate(String identityNumber) async {
  final dbFolder = await getMixinDocumentsDirectory();
  final dbFile = File(p.join(dbFolder.path, identityNumber, 'mixin.db'));
  final moorIsolate = await _createMoorIsolate(dbFile);
  final databaseConnection = await moorIsolate.connect();
  return MixinDatabase.connect(databaseConnection);
}

Future<MoorIsolate> _createMoorIsolate(File dbFile) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, dbFile),
  );

  return await receivePort.first as MoorIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  final executor = _openConnection(request.dbFile);
  final moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  request.sendMoorIsolate.send(moorIsolate);
}

class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.dbFile);

  final SendPort sendMoorIsolate;
  final File dbFile;
}
