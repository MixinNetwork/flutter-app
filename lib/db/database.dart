import 'dao/apps_dao.dart';
import 'dao/circle_conversations_dao.dart';
import 'dao/circles_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/jobs_dao.dart';
import 'dao/messages_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/participants_dao.dart';
import 'dao/sticker_albums_dao.dart';
import 'dao/sticker_relationships_dao.dart';
import 'dao/stickers_dao.dart';
import 'dao/users_dao.dart';
import 'mixin_database.dart';

class Database {
  Database(this._database) {
    appsDao = AppsDao(_database);
    conversationDao = ConversationsDao(_database);
    circlesDao = CirclesDao(_database);
    circleConversationDao = CircleConversationDao(_database);
    floodMessagesDao = FloodMessagesDao(_database);
    messagesDao = MessagesDao(_database);
    jobsDao = JobsDao(_database);
    participantsDao = ParticipantsDao(_database);
    userDao = UserDao(_database);
    stickerDao = StickerDao(_database);
    stickerAlbumsDao = StickerAlbumsDao(_database);
    stickerRelationshipsDao = StickerRelationshipsDao(_database);
    participantSessionDao = ParticipantSessionDao(_database);
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  final MixinDatabase _database;

  late final AppsDao appsDao;

  late final MessagesDao messagesDao;

  late final ConversationsDao conversationDao;

  late final CirclesDao circlesDao;

  late final CircleConversationDao circleConversationDao;

  late final FloodMessagesDao floodMessagesDao;

  late final JobsDao jobsDao;

  late final ParticipantsDao participantsDao;

  late final UserDao userDao;

  late final ParticipantSessionDao participantSessionDao;

  late final StickerDao stickerDao;

  late final StickerAlbumsDao stickerAlbumsDao;

  late final StickerRelationshipsDao stickerRelationshipsDao;

  Future<void> dispose() async {
    await _database.eventBus.dispose();
    await _database.close();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }

  Future<T> transaction<T>(Future<T> Function() action) =>
      _database.transaction<T>(action);
}
