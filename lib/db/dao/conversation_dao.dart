import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, Conversation;
import 'package:rxdart/rxdart.dart';

import '../../utils/extension/extension.dart';
import '../converter/conversation_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
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
      .throttleTime(const Duration(milliseconds: 330), trailing: true);

  late Stream<int> allUnseenIgnoreMuteMessageCountEvent = db
      .tableUpdates(TableUpdateQuery.onAllTables([
        db.conversations,
        db.users,
      ]))
      .asyncMap((event) => allUnseenIgnoreMuteMessageCount().getSingle())
      .where((event) => event != null)
      .map((event) => event!);

  Selectable<int?> allUnseenIgnoreMuteMessageCount() =>
      db.baseUnseenMessageCount(
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
      );

  Future<int> insert(Insertable<Conversation> conversation) async {
    final result =
        await into(db.conversations).insertOnConflictUpdate(conversation);
    return result;
  }

  Selectable<Conversation?> conversationById(String conversationId) =>
      (select(db.conversations)
        ..where((tbl) => tbl.conversationId.equals(conversationId)));

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

  Selectable<int> _baseConversationItemCount(
          Expression<bool?> Function(Conversations conversation, Users owner,
                  CircleConversations circleConversation)
              where) =>
      db.baseConversationItemCount((conversation, owner, circleConversation) =>
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
              limit) =>
      db.baseConversationItems(
          (Conversations conversation,
                  Users owner,
                  CircleConversations circleConversation,
                  Messages message,
                  Users lastMessageSender,
                  Snapshots snapshot,
                  Users participant) =>
              where(
                conversation,
                owner,
                circleConversation,
                message,
                lastMessageSender,
                snapshot,
                participant,
              ),
          _baseConversationItemOrder,
          limit);

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

  Selectable<BaseUnseenConversationCountResult> _baseUnseenConversationCount(
          Expression<bool?> Function(Conversations conversation, Users owner)
              where) =>
      db.baseUnseenConversationCount((conversation, owner) =>
          conversation.unseenMessageCount.isBiggerThanValue(0) &
          where(conversation, owner));

  Selectable<BaseUnseenConversationCountResult>
      contactUnseenConversationCount() =>
          _baseUnseenConversationCount(_contactWhere);

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

  Selectable<BaseUnseenConversationCountResult>
      strangerUnseenConversationCount() =>
          _baseUnseenConversationCount(_strangerWhere);

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

  Selectable<BaseUnseenConversationCountResult>
      groupUnseenConversationCount() =>
          _baseUnseenConversationCount(_groupWhere);

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

  Selectable<BaseUnseenConversationCountResult> botUnseenConversationCount() =>
      _baseUnseenConversationCount(_botWhere);

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
      );

  Selectable<ConversationItem> conversationItems() => _baseConversationItems(
        (conversation, _, __, ___, ____, ______, _______) =>
            conversation.category.isIn(['CONTACT', 'GROUP']),
        (_, __, ___, ____, ______, _______, ________) => maxLimit,
      );

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
      db.circleConversations.circleId.equals(circleId));

  Future<int> updateLastMessageId(
    String conversationId,
    String messageId,
    DateTime lastMessageCreatedAt,
    int unseenMessageCount,
  ) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        ConversationsCompanion(
          lastMessageId: Value(messageId),
          lastMessageCreatedAt: Value(lastMessageCreatedAt),
          unseenMessageCount: Value(unseenMessageCount),
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
        ConversationsCompanion(pinTime: const Value(null)),
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

  Future<bool> hasConversation(String conversationId) => db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId),
      );
}
