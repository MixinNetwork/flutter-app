import 'dart:io';

import 'package:flutter_app/db/dao/hyperlinks_dao.dart';
import 'package:flutter_app/db/dao/jobs_dao.dart';
import 'package:flutter_app/db/dao/message_mentions_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/dao/messages_history_dao.dart';
import 'package:flutter_app/db/dao/participants_dao.dart';
import 'package:flutter_app/db/dao/resend_session_messages_dao.dart';
import 'package:flutter_app/db/dao/stickers_dao.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
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
  ParticipantsDao,
  ResendSessionMessagesDao,
  SentSessionSenderKeysDao,
  SnapshotsDao,
  StickerDao,
  StickerAlbumsDao,
  StickerRelationshipsDao,
  UserDao,
])
class MixinDatabase extends _$MixinDatabase {
  MixinDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mixin.db'));
    return VmDatabase(file);
  });
}
