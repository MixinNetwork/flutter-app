import 'package:flutter_app/db/insert_or_update_event_server.dart';

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
    final _database = MixinDatabase(identityNumber);
    insertOrUpdateEventServer = InsertOrUpdateEventServer();
    appsDao = AppsDao(_database);
    conversationDao = ConversationsDao(_database);
    floodMessagesDao = FloodMessagesDao(_database);
    messagesDao = MessagesDao(_database);
    jobsDao = JobsDao(_database);
    participantsDao = ParticipantsDao(_database);
    userDao = UserDao(_database);
    conversationDao.insertOrUpdateEventServer = insertOrUpdateEventServer;
    messagesDao.insertOrUpdateEventServer = insertOrUpdateEventServer;
  }

  // static MixinDatabase _database;
  // static Future init() async {
  //   _database = await getMixinDatabaseConnection('3910');
  // }

  InsertOrUpdateEventServer insertOrUpdateEventServer;

  AppsDao appsDao;

  MessagesDao messagesDao;

  ConversationsDao conversationDao;

  FloodMessagesDao floodMessagesDao;

  JobsDao jobsDao;

  ParticipantsDao participantsDao;

  UserDao userDao;
}
