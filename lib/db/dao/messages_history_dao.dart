import 'package:moor/moor.dart';

import '../mixin_database.dart';

part 'messages_history_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class MessagesHistoryDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesHistoryDaoMixin {
  MessagesHistoryDao(MixinDatabase db) : super(db);

  Future<int> insert(MessagesHistoryData messagesHistory) =>
      into(db.messagesHistory).insertOnConflictUpdate(messagesHistory);

  Future deleteMessagesHistory(MessagesHistoryData messagesHistory) =>
      delete(db.messagesHistory).delete(messagesHistory);

  Selectable<MessagesHistoryData> findMessageHistoryById(String messageId) =>
      select(db.messagesHistory)
        ..where((tbl) => tbl.messageId.equals(messageId));
}
