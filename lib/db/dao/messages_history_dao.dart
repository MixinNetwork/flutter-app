import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'messages_history_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class MessagesHistoryDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  MessagesHistoryDao(MixinDatabase db) : super(db);

  Future<int> insert(MessagesHistoryData messagesHistory) =>
      into(db.messagesHistory).insertOnConflictUpdate(messagesHistory);

  Future deleteMessagesHistory(MessagesHistoryData messagesHistory) =>
      delete(db.messagesHistory).delete(messagesHistory);
}
