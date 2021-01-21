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

  Selectable<ConversationItem> conversations(
    DateTime oldestCreatedAt,
    int limit, [
    List<String> excludeId = const [],
  ]) =>
      db.conversationItems(excludeId, oldestCreatedAt, limit);

  Selectable<ConversationItem> contactConversations(
    DateTime oldestCreatedAt,
    int limit, [
    List<String> excludeId = const [],
  ]) =>
      db.contactConversations(excludeId, oldestCreatedAt, limit);

  Selectable<ConversationItem> strangerConversations(
    DateTime oldestCreatedAt,
    int limit, [
    List<String> excludeId = const [],
  ]) =>
      db.strangerConversations(excludeId, oldestCreatedAt, limit);

  Selectable<ConversationItem> groupConversations(
    DateTime oldestCreatedAt,
    int limit, [
    List<String> excludeId = const [],
  ]) =>
      db.groupConversations(excludeId, oldestCreatedAt, limit);

  Selectable<ConversationItem> botConversations(
    DateTime oldestCreatedAt,
    int limit, [
    List<String> excludeId = const [],
  ]) =>
      db.botConversations(excludeId, oldestCreatedAt, limit);

  Future<int> updateLastMessageId(String conversationId, String messageId) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(lastMessageId: Value(messageId)));
}
