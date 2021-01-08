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
    database = MixinDatabase(identityNumber);
    conversationDao = ConversationsDao(database);
    floodMessagesDao = FloodMessagesDao(database);
    messagesDao = MessagesDao(database);
    jobsDao = JobsDao(database);
    participantsDao = ParticipantsDao(database);
    userDao = UserDao(database);
  }

  MixinDatabase database;

  AppsDao appsDao;

  MessagesDao messagesDao;

  ConversationsDao conversationDao;

  FloodMessagesDao floodMessagesDao;

  JobsDao jobsDao;

  ParticipantsDao participantsDao;

  UserDao userDao;
}
