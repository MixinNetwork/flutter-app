import 'dao/conversations_dao.dart';
import 'dao/flood_messages_dao.dart';
import 'mixin_database.dart';

class Database {
  factory Database() {
    return _singleton;
  }

  Database._internal() {
    database = MixinDatabase();
    conversationDao = ConversationsDao(database);
    floodMessagesDao = FloodMessagesDao(database);
  }

  static final Database _singleton = Database._internal();

  MixinDatabase database;

  ConversationsDao conversationDao;

  FloodMessagesDao floodMessagesDao;
}
