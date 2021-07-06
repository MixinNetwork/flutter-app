import 'dart:async';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, Conversation;
import 'package:moor/moor.dart';

import '../../utils/string_extension.dart';
import '../converter/conversation_status_type_converter.dart';
import '../mixin_database.dart';

part 'conversation_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(MixinDatabase db) : super(db);

  late Stream<void> updateEvent = db.tableUpdates(TableUpdateQuery.onAllTables([
    db.conversations,
    db.users,
    db.messages,
    db.snapshots,
    db.messageMentions,
    db.circleConversations,
  ]));

  late Stream<int> allUnseenMessageCountEvent = db
      .tableUpdates(TableUpdateQuery.onAllTables([
        db.conversations,
      ]))
      .asyncMap(
          (event) => db.allUnseenMessageCount(DateTime.now()).getSingleOrNull())
      .where((event) => event != null)
      .map((event) => event!);

  Future<int?> allUnseenMessageCount() =>
      db.allUnseenMessageCount(DateTime.now()).getSingleOrNull();

  Future<int> insert(Insertable<Conversation> conversation) async {
    final result =
        await into(db.conversations).insertOnConflictUpdate(conversation);
    return result;
  }

  Selectable<Conversation?> conversationById(String conversationId) =>
      (select(db.conversations)
        ..where((tbl) => tbl.conversationId.equals(conversationId)));

  Selectable<ConversationItem> chatConversations(
    int limit,
    int offset,
  ) =>
      db.chatConversations(limit, offset);

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

  Future<int> updateLastMessageId(
    String conversationId,
    String messageId,
    DateTime lastMessageCreatedAt,
  ) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        ConversationsCompanion(
          lastMessageId: Value(messageId),
          lastMessageCreatedAt: Value(lastMessageCreatedAt),
        ),
      );

  Selectable<int> chatConversationCount() => db.chatConversationCount();

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
          String conversationId, ConversationStatus status) =>
      (db.update(db.conversations)
            ..where((tbl) =>
                tbl.conversationId.equals(conversationId) &
                tbl.status
                    .equals(const ConversationStatusTypeConverter()
                        .mapToSql(status))
                    .not()))
          .write(ConversationsCompanion(status: Value(status)));

  Selectable<ConversationItem> conversationItem(String conversationId) =>
      db.conversationItem(conversationId);

  Selectable<ConversationItem> conversationItems() => db.conversationItems();

  Selectable<SearchConversationItem> fuzzySearchConversation(String query) =>
      db.fuzzySearchConversation(query.trim().escapeSql());

  Future<ConversationItem?> conversationByUserId(String id) =>
      db.conversationByOwnerId(id).getSingleOrNull();

  Selectable<ConversationItem> conversationsByCircleId(
          String circleId, int limit, int offset) =>
      db.conversationsByCircleId(circleId, limit, offset);

  Selectable<int> conversationsCountByCircleId(String circleId) =>
      db.conversationsCountByCircleId(circleId);

  Selectable<int> conversationParticipantsCount(String conversationId) =>
      db.conversationParticipantsCount(conversationId);

  Selectable<String?> announcement(String conversationId) =>
      db.announcement(conversationId);

  Selectable<Participant> participantById(
          String conversationId, String userId) =>
      db.participantById(conversationId, userId);

  Selectable<ConversationStorageUsage> conversationStorageUsage() =>
      db.conversationStorageUsage();

  Future<void> updateConversation(ConversationResponse conversation) =>
      db.transaction(() async {
        await insert(
          ConversationsCompanion(
            conversationId: Value(conversation.conversationId),
            ownerId: Value(conversation.creatorId),
            category: Value(conversation.category),
            name: Value(conversation.name),
            iconUrl: Value(conversation.iconUrl),
            announcement: Value(conversation.announcement),
            codeUrl: Value(conversation.codeUrl),
            createdAt: Value(conversation.createdAt),
            status: const Value(ConversationStatus.success),
            muteUntil: Value(DateTime.tryParse(conversation.muteUntil)),
          ),
        );
        await Future.wait(
          conversation.participants.map(
            (participant) => db.participantDao.insert(
              Participant(
                conversationId: conversation.conversationId,
                userId: participant.userId,
                createdAt: participant.createdAt ?? DateTime.now(),
                role: participant.role,
              ),
            ),
          ),
        );
      });

  Future<int> updateCodeUrl(String conversationId, String codeUrl) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(codeUrl: Value(codeUrl)));

  Future<int> updateMuteUntil(String conversationId, String muteUntil) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(
              muteUntil: Value(DateTime.tryParse(muteUntil))));

  Future<int> updateDraft(String conversationId, String draft) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(draft: Value(draft)));
}
