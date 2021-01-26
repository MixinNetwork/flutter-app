import 'dart:async';

import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'conversations_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationsDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationsDaoMixin {
  ConversationsDao(MixinDatabase db) : super(db);

  Stream<ConversationItem> _updateConversionStream;
  Stream<ConversationItem> get updateConversion =>
      _updateConversionStream ??= db.eventBus
          .watch<String>(DatabaseEvent.updateConversion)
          .asyncMap((e) => db.conversationItem(e).getSingle())
          .handleError((e) => null)
          .where((event) => event != null);

  Stream<Null> get updateEvent => db.tableUpdates(TableUpdateQuery.onAllTables([
        db.conversations,
        db.users,
        db.messages,
        db.snapshots,
        db.messageMentions,
      ]));

  Future<int> insert(Conversation conversation) async {
    final result =
        await into(db.conversations).insertOnConflictUpdate(conversation);
    db.eventBus
        .send(DatabaseEvent.updateConversion, conversation.conversationId);
    return result;
  }

  Future<Conversation> getConversationById(String conversationId) {
    final query = select(db.conversations)
      ..where((tbl) => tbl.conversationId.equals(conversationId));
    return query.getSingle();
  }

  Selectable<ConversationItem> contactConversations(
    int limit,
    int offset,
  ) =>
      db.contactConversations(limit, offset);

  Selectable<ConversationItem> strangerConversations(
    int limit,
    int offset,
  ) =>
      db.strangerConversations(limit, offset);

  Selectable<ConversationItem> groupConversations(
    int limit,
    int offset,
  ) =>
      db.groupConversations(limit, offset);

  Selectable<ConversationItem> botConversations(
    int limit,
    int offset,
  ) =>
      db.botConversations(limit, offset);

  Future<int> updateLastMessageId(String conversationId, String messageId) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(lastMessageId: Value(messageId)));

  Selectable<int> contactConversationCount() => db.contactConversationCount();

  Selectable<int> groupConversationCount() => db.groupConversationCount();

  Selectable<int> botConversationCount() => db.botConversationCount();

  Selectable<int> strangerConversationCount() => db.strangerConversationCount();
}
