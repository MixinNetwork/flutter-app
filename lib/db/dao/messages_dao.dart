import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
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

  Selectable<MessageItem> messageByConversationId(
    String conversationId,
    int limit, {
    DateTime oldestCreatedAt,
    List<String> excludeId = const [],
  }) =>
      db.messageByConversationId(
        conversationId,
        excludeId,
        oldestCreatedAt,
        limit,
      );

  Stream<List<SendingMessage>> sendingMessage(String messageId) {
    return db.sendingMessage(messageId).watch();
  }
}
