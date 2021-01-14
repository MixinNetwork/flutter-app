import 'dart:io';
import 'dart:isolate';

import 'package:flutter_app/db/dao/hyperlinks_dao.dart';
import 'package:flutter_app/db/dao/jobs_dao.dart';
import 'package:flutter_app/db/dao/message_mentions_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/dao/messages_history_dao.dart';
import 'package:flutter_app/db/dao/participants_dao.dart';
import 'package:flutter_app/db/dao/resend_session_messages_dao.dart';
import 'package:flutter_app/db/dao/stickers_dao.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
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

@UseMoor(include: {
  'mixin.moor'
}, daos: [
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
], queries: {})
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase(String identityNumber) : super(_openConnection(identityNumber));

  MixinDatabase.connect(DatabaseConnection c) : super.connect(c);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection(String identityNumber) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, identityNumber, 'mixin.db'));
    return VmDatabase(file);
  });
}

// todo
// ignore: unused_element
Future<MoorIsolate> _createMoorIsolate(String identityNumber) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, identityNumber),
  );

  return (await receivePort.first as MoorIsolate);
}

void _startBackground(_IsolateStartRequest request) {
  final executor = _openConnection(request.identityNumber);
  final moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  request.sendMoorIsolate.send(moorIsolate);
}

class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.identityNumber);

  final SendPort sendMoorIsolate;
  final String identityNumber;
}
