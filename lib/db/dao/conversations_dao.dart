import 'dart:async';

import 'package:flutter_app/db/insert_or_update_event_server.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'conversations_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationsDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationsDaoMixin {
  ConversationsDao(MixinDatabase db) : super(db);

  InsertOrUpdateEventServer _insertOrUpdateEventServer;

  set insertOrUpdateEventServer(
      InsertOrUpdateEventServer insertOrUpdateEventServer) {
    _insertOrUpdateEventServer = insertOrUpdateEventServer;
    insertOrUpdateEventServer.conversationInsertOrUpdateStream =
        insertOrUpdateEventServer.conversationInsertOrUpdateController.stream
            .where((event) => event != null)
            .asyncMap((id) async => db.conversationItem(id).getSingle())
            .where((event) => event != null);
  }

  Future<int> insert(Conversation conversation) async {
    final result =
        await into(db.conversations).insertOnConflictUpdate(conversation);
    _insertOrUpdateEventServer.conversationInsertOrUpdateController
        .add(conversation.conversationId);
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
    DateTime lastCreatedAt,
    int limit, [
    List<String> loadedConversationId = const [],
  ]) =>
      db.conversationItems(loadedConversationId, lastCreatedAt, limit).get();
}
