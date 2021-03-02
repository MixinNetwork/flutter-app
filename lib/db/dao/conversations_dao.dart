import 'dart:async';

import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    show ConversationStatus;

part 'conversations_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationsDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationsDaoMixin {
  ConversationsDao(MixinDatabase db) : super(db);

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
    return result;
  }

  Future<Conversation?> getConversationById(String conversationId) async {
    final list = await (select(db.conversations)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .get();
    return list.isEmpty ? null : list.first;
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

  Future<int> pin(String conversationId) => (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        ConversationsCompanion(pinTime: Value(DateTime.now())),
      );

  Future<int> unpin(String conversationId) => (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        const ConversationsCompanion(pinTime: Value(null)),
      );

  Future<int> deleteConversation(String conversationId) =>
      (delete(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Future<int> updateConversationStatusById(
          String conversationId, ConversationStatus status) async =>
      await db.customUpdate(
          'UPDATE conversations SET status = ? WHERE conversation_id = ?',
          variables: [
            Variable.withString(conversationId),
            Variable<ConversationStatus>(status)
          ]);
}
