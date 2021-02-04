import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_app/db/converter/conversation_category_type_converter.dart';
import 'package:flutter_app/db/converter/conversation_status_type_converter.dart';
import 'package:flutter_app/db/converter/media_status_type_converter.dart';
import 'package:flutter_app/db/converter/message_category_type_converter.dart';
import 'package:flutter_app/db/converter/message_status_type_converter.dart';
import 'package:flutter_app/db/converter/user_relationship_converter.dart';
import 'package:flutter_app/db/converter/participant_role_converter.dart';
import 'package:flutter_app/db/converter/millis_date_converter.dart';
import 'package:flutter_app/db/dao/hyperlinks_dao.dart';
import 'package:flutter_app/db/dao/jobs_dao.dart';
import 'package:flutter_app/db/dao/message_mentions_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/dao/messages_history_dao.dart';
import 'package:flutter_app/db/dao/participants_dao.dart';
import 'package:flutter_app/db/dao/resend_session_messages_dao.dart';
import 'package:flutter_app/db/dao/stickers_dao.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/load_balancer_utils.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';

// These imports are only needed to open the database
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dao/addresses_dao.dart';
import 'dao/apps_dao.dart';
import 'dao/assets_dao.dart';
import 'dao/circle_conversations_dao.dart';
import 'dao/circles_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/offsets_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/sent_session_sender_keys_dao.dart';
import 'dao/snapshots_dao.dart';
import 'dao/sticker_albums_dao.dart';
import 'dao/sticker_relationships_dao.dart';

part 'mixin_database.g.dart';

@UseMoor(
  include: {
    'moor/mixin.moor',
    'moor/dao/conversation.moor',
    'moor/dao/message.moor',
    'moor/dao/participant.moor',
    'moor/dao/sticker.moor',
    'moor/dao/sticker_album.moor',
  },
  daos: [
    AddressesDao,
    AppsDao,
    AssetsDao,
    CircleConversationDao,
    CirclesDao,
    ConversationsDao,
    FloodMessagesDao,
    HyperlinksDao,
    JobsDao,
    MessageMentionsDao,
    MessagesDao,
    MessagesHistoryDao,
    OffsetsDao,
    ParticipantsDao,
    ParticipantSessionDao,
    ResendSessionMessagesDao,
    SentSessionSenderKeysDao,
    SnapshotsDao,
    StickerDao,
    StickerAlbumsDao,
    StickerRelationshipsDao,
    UserDao,
  ],
  queries: {},
)
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase.connect(DatabaseConnection c) : super.connect(c);

  @override
  int get schemaVersion {
    return 1;
  }

  final eventBus = DataBaseEventBus();
}

LazyDatabase _openConnection(File dbFile) {
  return LazyDatabase(() async {
    return VmDatabase(dbFile);
  });
}

Future<MixinDatabase> createMoorIsolate(String identityNumber) async {
  final dbFolder = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dbFolder.path, identityNumber, 'mixin.db'));
  final moorIsolate =
      await LoadBalancerUtils.runLoadBalancer(_createMoorIsolate, dbFile);
  final databaseConnection = await (moorIsolate.connect());
  return MixinDatabase.connect(databaseConnection);
}

Future<MoorIsolate> _createMoorIsolate(File dbFile) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, dbFile),
  );

  return (await receivePort.first as MoorIsolate);
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
