import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:moor/moor.dart';

part 'messages_dao.g.dart';

@UseDao(tables: [Messages])
class MessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(MixinDatabase db) : super(db);

  Stream<Null> get updateEvent => db.tableUpdates(TableUpdateQuery.onAllTables([
        db.messages,
        db.users,
        db.snapshots,
        db.assets,
        db.stickers,
        db.hyperlinks,
        db.messageMentions,
        db.conversations,
      ]));

  Future<int> insert(Message message, String userId) async {
    final result = await into(db.messages).insertOnConflictUpdate(message);
    await db.conversationsDao
        .updateLastMessageId(message.conversationId, message.messageId);
    await _takeUnseen(userId, message.conversationId);
    db.eventBus.send(DatabaseEvent.updateConversion, message.conversationId);
    return result;
  }

  Future deleteMessage(Message message) => delete(db.messages).delete(message);

  Future<SendingMessage> sendingMessage(String messageId) {
    return db.sendingMessage(messageId).getSingle();
  }

  Future<int> updateMessageStatusById(String messageId, MessageStatus status) {
    return (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
  }

  Future<int> _takeUnseen(String userId, String conversationId) {
    return db.customUpdate(
        'UPDATE conversations SET unseen_message_count = (SELECT count(1) FROM messages m WHERE m.conversation_id = ? AND m.user_id != ? AND m.status IN (\'SENT\', \'DELIVERED\')) WHERE conversation_id = ?',
        variables: [
          Variable.withString(conversationId),
          Variable.withString(userId),
          Variable.withString(conversationId)
        ]);
  }

  Selectable<MessageItem> messagesByConversationId(
    String conversationId,
    int limit, {
    int offset = 0,
  }) =>
      db.messagesByConversationId(
        conversationId,
        offset,
        limit,
      );

  Selectable<int> messageCountByConversationId(String conversationId) {
    final countExp = countAll();
    return (db.selectOnly(db.messages)
          ..addColumns([countExp])
          ..where(db.messages.conversationId.equals(conversationId)))
        .map((row) => row.read(countExp));
  }
}
