import 'dart:async';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, Conversation;
import 'package:moor/moor.dart';

import '../../utils/string_extension.dart';
import '../converter/conversation_status_type_converter.dart';
import '../mixin_database.dart';
import '../util/util.dart';

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

  Expression<bool?> _baseConversationItemWhere(Conversations conversation,
          [Users? owner,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant]) =>
      conversation.status.isBiggerOrEqualValue(2);

  OrderBy _baseConversationItemOrder(
          Conversations conversation,
          Users user,
          Messages message,
          Users lastMessageSender,
          Snapshots snapshot,
          Users participant) =>
      OrderBy(
        [
          OrderingTerm.desc(conversation.pinTime),
          OrderingTerm.desc(conversation.lastMessageCreatedAt),
          OrderingTerm.desc(conversation.createdAt),
        ],
      );

  Selectable<int> _baseConversationItemCount(
          Expression<bool?> Function(Conversations conversation, Users owner)
              where) =>
      db.baseConversationItemCount((conversation, owner) =>
          _baseConversationItemWhere(conversation, owner) &
          where(conversation, owner));

  Selectable<ConversationItem> _baseConversationItems(
    Expression<bool?> Function(
            Conversations conversation,
            Users owner,
            Messages message,
            Users lastMessageSender,
            Snapshots snapshot,
            Users participant)
        where,
    Limit Function(Conversations conversation, Users user, Messages message,
            Users lastMessageSender, Snapshots snapshot, Users participant)
        limit, {
    bool useBaseWhere = true,
  }) =>
      db.baseConversationItems((Conversations conversation,
          Users owner,
          Messages message,
          Users lastMessageSender,
          Snapshots snapshot,
          Users participant) {
        final expression = where(conversation, owner, message,
            lastMessageSender, snapshot, participant);
        if (useBaseWhere) {
          return expression &
              _baseConversationItemWhere(conversation, owner, message,
                  lastMessageSender, snapshot, participant);
        }
        return expression;
      }, _baseConversationItemOrder, limit);

  Expression<bool?> _chatWhere(
          Conversations conversation,
          Users? owner,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant) =>
      conversation.category.isIn(['CONTACT', 'GROUP']);

  Selectable<int> chatConversationCount() =>
      _baseConversationItemCount((conversation, owner) =>
          _chatWhere(conversation, owner, null, null, null, null));

  Selectable<ConversationItem> chatConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _chatWhere,
        (_, __, ___, ____, ______, _______) => Limit(limit, offset),
      );

  Expression<bool?> _contactWhere(
          Conversations conversation,
          Users owner,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.relationship.equalsValue(UserRelationship.friend) &
      owner.appId.isNull();

  Selectable<int> contactConversationCount() =>
      _baseConversationItemCount((conversation, owner) =>
          _contactWhere(conversation, owner, null, null, null, null));

  Selectable<ConversationItem> contactConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _contactWhere,
        (_, __, ___, ____, ______, _______) => Limit(limit, offset),
      );

  Expression<bool?> _strangerWhere(
          Conversations conversation,
          Users owner,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.relationship.equalsValue(UserRelationship.stranger) &
      owner.appId.isNull();

  Selectable<int> strangerConversationCount() =>
      _baseConversationItemCount((conversation, owner) =>
          _strangerWhere(conversation, owner, null, null, null, null));

  Selectable<ConversationItem> strangerConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _strangerWhere,
        (_, __, ___, ____, ______, _______) => Limit(limit, offset),
      );

  Expression<bool?> _groupWhere(
          Conversations conversation,
          Users? owner,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant) =>
      conversation.category.equalsValue(ConversationCategory.contact);

  Selectable<int> groupConversationCount() =>
      _baseConversationItemCount((conversation, owner) =>
          _groupWhere(conversation, owner, null, null, null, null));

  Selectable<ConversationItem> groupConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _groupWhere,
        (_, __, ___, ____, ______, _______) => Limit(limit, offset),
      );

  Expression<bool?> _botWhere(
          Conversations conversation,
          Users owner,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.appId.isNotNull();

  Selectable<int> botConversationCount() =>
      _baseConversationItemCount((conversation, owner) =>
          _botWhere(conversation, owner, null, null, null, null));

  Selectable<ConversationItem> botConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _botWhere,
        (_, __, ___, ____, ______, _______) => Limit(limit, offset),
      );

  Selectable<ConversationItem> conversationItem(String conversationId) =>
      _baseConversationItems(
        (conversation, _, __, ___, ____, ______) =>
            conversation.conversationId.equals(conversationId),
        (_, __, ___, ____, ______, _______) => Limit(1, null),
        useBaseWhere: false,
      );

  Selectable<ConversationItem> conversationItems() => _baseConversationItems(
        (conversation, _, __, ___, ____, ______) =>
            conversation.category.isIn(['CONTACT', 'GROUP']),
        (_, __, ___, ____, ______, _______) => maxLimit,
      );

  Selectable<int> conversationsCountByCircleId(String circleId) =>
      db.baseConversationItemCountWithCircleConversation(
          (circleConversation, conversation, owner) =>
              _baseConversationItemWhere(conversation, owner) &
              circleConversation.circleId.equals(circleId));

  Selectable<ConversationItem> conversationsByCircleId(
          String circleId, int limit, int offset) =>
      db.baseConversationItemsWithCircleConversation(
          (circleConversation, conversation, owner, lastMessage,
                  lastMessageSender, snapshot, participant) =>
              _baseConversationItemWhere(conversation, owner, lastMessage, lastMessageSender, snapshot, participant) &
              circleConversation.circleId.equals(circleId),
          (circleConversation, conversation, owner, lastMessage,
                  lastMessageSender, snapshot, participant) =>
              _baseConversationItemOrder(conversation, owner, lastMessage,
                  lastMessageSender, snapshot, participant),
          (circleConversation, conversation, owner, lastMessage,
                  lastMessageSender, snapshot, participant) =>
              Limit(limit, offset));

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

  Selectable<SearchConversationItem> fuzzySearchConversation(String query) =>
      db.fuzzySearchConversation(query.trim().escapeSql());

  Selectable<String?> announcement(String conversationId) =>
      (db.selectOnly(db.conversations)
            ..addColumns([db.conversations.announcement])
            ..where(db.conversations.conversationId.equals(conversationId))
            ..limit(1))
          .map((row) => row.read(db.conversations.announcement));

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
