import 'package:drift/drift.dart';

import '../mixin_database.dart';

part 'message_history_dao.g.dart';

@DriftAccessor()
class MessageHistoryDao extends DatabaseAccessor<MixinDatabase>
    with _$MessageHistoryDaoMixin {
  MessageHistoryDao(super.db);

  Future<int> insert(MessagesHistoryData messagesHistory) =>
      into(db.messagesHistory).insertOnConflictUpdate(messagesHistory);

  Future<void> insertList(Iterable<MessagesHistoryData> list) => batch(
    (batch) => batch.insertAll(
      db.messagesHistory,
      list,
      mode: InsertMode.insertOrReplace,
    ),
  );

  Future deleteMessagesHistory(MessagesHistoryData messagesHistory) =>
      delete(db.messagesHistory).delete(messagesHistory);

  Future<String?> findMessageHistoryById(String messageId) =>
      (db.selectOnly(db.messagesHistory)
            ..addColumns([db.messagesHistory.messageId])
            ..where(db.messagesHistory.messageId.equals(messageId)))
          .map((row) => row.read(db.messagesHistory.messageId))
          .getSingleOrNull();
}
