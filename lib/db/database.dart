import 'dao/apps_dao.dart';
import 'dao/circle_conversations_dao.dart';
import 'dao/circles_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/jobs_dao.dart';
import 'dao/message_mentions_dao.dart';
import 'dao/messages_dao.dart';
import 'dao/participant_session_dao.dart';
import 'dao/participants_dao.dart';
import 'dao/resend_session_messages_dao.dart';
import 'dao/sticker_albums_dao.dart';
import 'dao/sticker_relationships_dao.dart';
import 'dao/stickers_dao.dart';
import 'dao/users_dao.dart';
import 'mixin_database.dart';

class Database {
  Database(this.mixinDatabase) {
    appsDao = AppsDao(mixinDatabase);
    conversationDao = ConversationsDao(mixinDatabase);
    circlesDao = CirclesDao(mixinDatabase);
    circleConversationDao = CircleConversationDao(mixinDatabase);
    floodMessagesDao = FloodMessagesDao(mixinDatabase);
    messagesDao = MessagesDao(mixinDatabase);
    messageMentionsDao = MessageMentionsDao(mixinDatabase);
    jobsDao = JobsDao(mixinDatabase);
    participantsDao = ParticipantsDao(mixinDatabase);
    userDao = UserDao(mixinDatabase);
    stickerDao = StickerDao(mixinDatabase);
    stickerAlbumsDao = StickerAlbumsDao(mixinDatabase);
    stickerRelationshipsDao = StickerRelationshipsDao(mixinDatabase);
    participantSessionDao = ParticipantSessionDao(mixinDatabase);
    resendSessionMessagesDao = ResendSessionMessagesDao(mixinDatabase);
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  final MixinDatabase mixinDatabase;

  late final AppsDao appsDao;

  late final MessagesDao messagesDao;

  late final MessageMentionsDao messageMentionsDao;

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

  late final ResendSessionMessagesDao resendSessionMessagesDao;

  Future<void> dispose() async {
    await mixinDatabase.eventBus.dispose();
    await mixinDatabase.close();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }

  Future<T> transaction<T>(Future<T> Function() action) =>
      mixinDatabase.transaction<T>(action);
}
