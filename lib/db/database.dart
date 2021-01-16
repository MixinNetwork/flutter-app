import 'dao/apps_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/jobs_dao.dart';
import 'dao/messages_dao.dart';
import 'dao/participants_dao.dart';
import 'dao/users_dao.dart';
import 'mixin_database.dart';

class Database {
  Database(String identityNumber) {
    _database = MixinDatabase(identityNumber);
    appsDao = AppsDao(_database);
    conversationDao = ConversationsDao(_database);
    floodMessagesDao = FloodMessagesDao(_database);
    messagesDao = MessagesDao(_database);
    jobsDao = JobsDao(_database);
    participantsDao = ParticipantsDao(_database);
    userDao = UserDao(_database);
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  MixinDatabase _database;

  AppsDao appsDao;

  MessagesDao messagesDao;

  ConversationsDao conversationDao;

  FloodMessagesDao floodMessagesDao;

  JobsDao jobsDao;

  ParticipantsDao participantsDao;

  UserDao userDao;

  void dispose() {
    _database.eventBus.dispose();
    // dispose stream, https://github.com/simolus3/moor/issues/290
  }
}
