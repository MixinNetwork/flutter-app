import 'dart:async';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, Conversation;
import 'package:moor/moor.dart';
import 'package:rxdart/rxdart.dart';

import '../../utils/extension/extension.dart';
import '../converter/conversation_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'conversation_dao.g.dart';

@UseDao(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(MixinDatabase db) : super(db);

  late Stream<void> updateEvent = db
      .tableUpdates(TableUpdateQuery.onAllTables([
        db.conversations,
        db.users,
        db.messages,
        db.snapshots,
        db.messageMentions,
        db.circleConversations,
      ]))
      .throttleTime(const Duration(milliseconds: 20));

  late Stream<int> allUnseenIgnoreMuteMessageCountEvent = db
      .tableUpdates(TableUpdateQuery.onAllTables([
        db.conversations,
        db.users,
      ]))
      .asyncMap((event) => allUnseenIgnoreMuteMessageCount().getSingle())
      .where((event) => event != null)
      .map((event) => event!);

  Selectable<int?> allUnseenIgnoreMuteMessageCount() => _baseUnseenMessageCount(
        (conversation, owner, __) {
          final now = const MillisDateConverter().mapToSql(DateTime.now());
          final groupExpression =
              conversation.category.equalsValue(ConversationCategory.group) &
                  conversation.muteUntil.isSmallerOrEqualValue(now);
          final userExpression =
              conversation.category.equalsValue(ConversationCategory.contact) &
                  owner.muteUntil.isSmallerOrEqualValue(now);
          return groupExpression | userExpression;
        },
        useBaseWhere: false,
      );

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
          CircleConversations? circleConversation,
          Messages? message,
          Users? lastMessageSender,
          Snapshots? snapshot,
          Users? participant]) =>
      conversation.status.isBiggerOrEqualValue(2);

  OrderBy _baseConversationItemOrder(
          Conversations conversation,
          Users user,
          CircleConversations circleConversation,
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

  Selectable<int?> _baseUnseenMessageCount(
    Expression<bool?> Function(Conversations conversation, Users owner,
            CircleConversations circleConversation)
        where, {
    bool useBaseWhere = true,
  }) =>
      db.baseUnseenMessageCount((conversation, owner, circleConversation) {
        final expression = where(conversation, owner, circleConversation);
        if (useBaseWhere) {
          return _baseConversationItemWhere(
                  conversation, owner, circleConversation) &
              expression;
        }
        return expression;
      });

  Selectable<int> _baseConversationItemCount(
          Expression<bool?> Function(Conversations conversation, Users owner,
                  CircleConversations circleConversation)
              where) =>
      db.baseConversationItemCount((conversation, owner, circleConversation) =>
          _baseConversationItemWhere(conversation, owner, circleConversation) &
          where(conversation, owner, circleConversation));

  Selectable<ConversationItem> _baseConversationItems(
    Expression<bool?> Function(
            Conversations conversation,
            Users owner,
            CircleConversations circleConversation,
            Messages message,
            Users lastMessageSender,
            Snapshots snapshot,
            Users participant)
        where,
    Limit Function(
      Conversations conversation,
      Users user,
      CircleConversations circleConversation,
      Messages message,
      Users lastMessageSender,
      Snapshots snapshot,
      Users participant,
    )
        limit, {
    bool useBaseWhere = true,
  }) =>
      db.baseConversationItems((Conversations conversation,
          Users owner,
          CircleConversations circleConversation,
          Messages message,
          Users lastMessageSender,
          Snapshots snapshot,
          Users participant) {
        final expression = where(
          conversation,
          owner,
          circleConversation,
          message,
          lastMessageSender,
          snapshot,
          participant,
        );
        if (useBaseWhere) {
          return expression &
              _baseConversationItemWhere(
                  conversation,
                  owner,
                  circleConversation,
                  message,
                  lastMessageSender,
                  snapshot,
                  participant);
        }
        return expression;
      }, _baseConversationItemOrder, limit);

  Future<bool> _conversationHasData(Expression<bool?> predicate) => db.hasData(
      db.conversations,
      [
        innerJoin(db.users, db.conversations.ownerId.equalsExp(db.users.userId),
            useColumns: false)
      ],
      predicate);

  Expression<bool?> _chatWhere(
    Conversations conversation, [
    Users? owner,
    CircleConversations? circleConversation,
    Messages? message,
    Users? lastMessageSender,
    Snapshots? snapshot,
    Users? participant,
  ]) =>
      conversation.category.isIn(['CONTACT', 'GROUP']);

  Selectable<int> chatConversationCount() =>
      _baseConversationItemCount(_chatWhere);

  Selectable<ConversationItem> chatConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _chatWhere,
        (_, __, ___, ____, ______, _______, ________) => Limit(limit, offset),
      );

  Future<bool> chatConversationHasData() =>
      _conversationHasData(_chatWhere(db.conversations));

  Expression<bool?> _contactWhere(
    Conversations conversation,
    Users owner, [
    CircleConversations? circleConversation,
    Messages? message,
    Users? lastMessageSender,
    Snapshots? snapshot,
    Users? participant,
  ]) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.relationship.equalsValue(UserRelationship.friend) &
      owner.appId.isNull();

  Selectable<int?> contactConversationUnseenMessageCount() =>
      _baseUnseenMessageCount(_contactWhere);

  Selectable<int> contactConversationCount() =>
      _baseConversationItemCount(_contactWhere);

  Selectable<ConversationItem> contactConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _contactWhere,
        (_, __, ___, ____, ______, _______, ________) => Limit(limit, offset),
      );

  Future<bool> contactConversationHasData() =>
      _conversationHasData(_contactWhere(db.conversations, db.users));

  Expression<bool?> _strangerWhere(
    Conversations conversation,
    Users owner, [
    CircleConversations? circleConversation,
    Messages? message,
    Users? lastMessageSender,
    Snapshots? snapshot,
    Users? participant,
  ]) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.relationship.equalsValue(UserRelationship.stranger) &
      owner.appId.isNull();

  Selectable<int?> strangerConversationUnseenMessageCount() =>
      _baseUnseenMessageCount(_strangerWhere);

  Selectable<int> strangerConversationCount() =>
      _baseConversationItemCount(_strangerWhere);

  Selectable<ConversationItem> strangerConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _strangerWhere,
        (_, __, ___, ____, ______, _______, ________) => Limit(limit, offset),
      );

  Future<bool> strangerConversationHasData() =>
      _conversationHasData(_strangerWhere(db.conversations, db.users));

  Expression<bool?> _groupWhere(
    Conversations conversation, [
    Users? owner,
    CircleConversations? circleConversation,
    Messages? message,
    Users? lastMessageSender,
    Snapshots? snapshot,
    Users? participant,
  ]) =>
      conversation.category.equalsValue(ConversationCategory.group);

  Selectable<int?> groupConversationUnseenMessageCount() =>
      _baseUnseenMessageCount(_groupWhere);

  Selectable<int> groupConversationCount() =>
      _baseConversationItemCount(_groupWhere);

  Future<bool> groupConversationHasData() =>
      _conversationHasData(_groupWhere(db.conversations));

  Selectable<ConversationItem> groupConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _groupWhere,
        (_, __, ___, ____, ______, _______, ________) => Limit(limit, offset),
      );

  Expression<bool?> _botWhere(
    Conversations conversation,
    Users owner, [
    CircleConversations? circleConversation,
    Messages? message,
    Users? lastMessageSender,
    Snapshots? snapshot,
    Users? participant,
  ]) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.appId.isNotNull();

  Selectable<int?> botConversationUnseenMessageCount() =>
      _baseUnseenMessageCount(_botWhere);

  Selectable<int> botConversationCount() =>
      _baseConversationItemCount(_botWhere);

  Selectable<ConversationItem> botConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        _botWhere,
        (_, __, ___, ____, ______, _______, ________) => Limit(limit, offset),
      );

  Future<bool> botConversationHasData() =>
      _conversationHasData(_botWhere(db.conversations, db.users));

  Selectable<ConversationItem> conversationItem(String conversationId) =>
      _baseConversationItems(
        (conversation, _, __, ___, ____, ______, _______) =>
            conversation.conversationId.equals(conversationId),
        (_, __, ___, ____, ______, _______, ________) => Limit(1, null),
        useBaseWhere: false,
      );

  Selectable<ConversationItem> conversationItems() => _baseConversationItems(
        (conversation, _, __, ___, ____, ______, _______) =>
            conversation.category.isIn(['CONTACT', 'GROUP']),
        (_, __, ___, ____, ______, _______, ________) => maxLimit,
      );

  Selectable<int?> conversationUnseenMessageCountByCircleId(String circleId) =>
      _baseUnseenMessageCount((_, __, circleConversation) =>
          circleConversation.circleId.equals(circleId));

  Selectable<int> conversationsCountByCircleId(String circleId) =>
      _baseConversationItemCount((_, __, circleConversation) =>
          circleConversation.circleId.equals(circleId));

  Selectable<ConversationItem> conversationsByCircleId(
          String circleId, int limit, int offset) =>
      _baseConversationItems(
        (_, __, circleConversation, ___, ____, _____, ______) =>
            circleConversation.circleId.equals(circleId),
        (_, __, ___, ____, ______, _______, ________) => Limit(limit, offset),
      );

  Future<bool> conversationHasDataByCircleId(String circleId) => db.hasData(
      db.circleConversations,
      [
        innerJoin(
          db.conversations,
          db.circleConversations.conversationId
              .equalsExp(db.conversations.conversationId),
          useColumns: false,
        )
      ],
      _baseConversationItemWhere(db.conversations) &
          db.circleConversations.circleId.equals(circleId));

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
