import 'dao/apps_dao.dart';
import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'dao/messages_dao.dart';
import 'dao/participants_dao.dart';
import 'dao/users_dao.dart';
import 'mixin_database.dart';

class Database {
  factory Database() {
    return _singleton;
  }

  Database._internal() {
    database = MixinDatabase();
    conversationDao = ConversationsDao(database);
    floodMessagesDao = FloodMessagesDao(database);
    participantsDao = ParticipantsDao(database);
    userDao = UserDao(database);
  }

  static final Database _singleton = Database._internal();

  MixinDatabase database;

  AppsDao appsDao;

  MessagesDao messagesDao;

  ConversationsDao conversationDao;

  FloodMessagesDao floodMessagesDao;

  ParticipantsDao participantsDao;

  UserDao userDao;
}
