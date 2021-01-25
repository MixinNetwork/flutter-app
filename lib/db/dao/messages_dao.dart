import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:moor/moor.dart';

part 'messages_dao.g.dart';

@UseDao(tables: [Messages])
class MessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(MixinDatabase db) : super(db);

  Future<int> insert(Message message) async {
    final result = await into(db.messages).insertOnConflictUpdate(message);
    await db.conversationsDao
        .updateLastMessageId(message.conversationId, message.messageId);
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
