import 'dart:async';

import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'conversations_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationsDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationsDaoMixin {
  ConversationsDao(MixinDatabase db) : super(db);

  Stream<ConversationItem> get insertOrMoveStream => db.eventBus
      .watch<String>(DatabaseEvent.insertOrMoveConversation)
      .asyncMap((id) async => db.conversationItem(id).getSingle())
      .where((event) => event != null);

  Future<int> insert(Conversation conversation) async {
    final result =
        await into(db.conversations).insertOnConflictUpdate(conversation);
    db.eventBus.send(
        DatabaseEvent.insertOrMoveConversation, conversation.conversationId);
    return result;
  }

  Stream<List<Conversation>> conversations() =>
      select(db.conversations).watch();

  Future<Conversation> getConversationById(String conversationId) {
    final query = select(db.conversations)
      ..where((tbl) => tbl.conversationId.equals(conversationId));
    return query.getSingle();
  }

  Future<List<ConversationItem>> conversationList(
    DateTime oldestCreatedAt,
    int limit, [
    List<String> loadedConversationId = const [],
  ]) =>
      db.conversationItems(loadedConversationId, oldestCreatedAt, limit).get();

  Future<int> updateLastMessageId(String conversationId, String messageId) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(lastMessageId: Value(messageId)));
}
