import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, Conversation;
import 'package:rxdart/rxdart.dart';

import '../../enum/encrypt_category.dart';
import '../../utils/extension/extension.dart';
import '../converter/conversation_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../mixin_database.dart';
import '../util/util.dart';
import 'app_dao.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  late Stream<Set<TableUpdate>> updateEvent = db
      .tableUpdates(TableUpdateQuery.onAllTables([
        db.conversations,
        db.users,
        db.messages,
        db.snapshots,
        db.messageMentions,
        db.circleConversations,
      ]))
      .throttleTime(kSlowThrottleDuration, trailing: true);

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
          final now = const MillisDateConverter().toSql(DateTime.now());
          final groupExpression =
              conversation.category.equalsValue(ConversationCategory.group) &
                  conversation.muteUntil.isSmallerOrEqualValue(now);
          final userExpression =
              conversation.category.equalsValue(ConversationCategory.contact) &
                  owner.muteUntil.isSmallerOrEqualValue(now);
          return groupExpression | userExpression;
        },
      );

  Future<int> insert(Insertable<Conversation> conversation) =>
      into(db.conversations).insertOnConflictUpdate(conversation);

  Selectable<Conversation?> conversationById(String conversationId) =>
      (select(db.conversations)
        ..where((tbl) => tbl.conversationId.equals(conversationId)));

  OrderBy _baseConversationItemOrder(Conversations conversation) => OrderBy(
        [
          OrderingTerm.desc(conversation.pinTime),
          OrderingTerm.desc(conversation.lastMessageCreatedAt),
          OrderingTerm.desc(conversation.createdAt),
        ],
      );

  Selectable<int> _baseConversationItemCount(
          Expression<bool> Function(Conversations conversation, Users owner,
                  CircleConversations circleConversation)
              where) =>
      db.baseConversationItemCount((conversation, owner, circleConversation) =>
          where(conversation, owner, circleConversation));

  Selectable<ConversationItem> _baseConversationItems(
          Expression<bool> Function(
                  Conversations conversation,
                  Users owner,
                  Messages message,
                  Users lastMessageSender,
                  Snapshots snapshot,
                  Users participant)
              where,
          Limit Function(
    Conversations conversation,
    Users user,
    Messages message,
    Users lastMessageSender,
    Snapshots snapshot,
    Users participant,
    ExpiredMessages em,
  )
              limit) =>
      db.baseConversationItems(
          (
            Conversations conversation,
            Users owner,
            Messages message,
            Users lastMessageSender,
            Snapshots snapshot,
            Users participant,
            ExpiredMessages em,
          ) =>
              where(
                conversation,
                owner,
                message,
                lastMessageSender,
                snapshot,
                participant,
              ),
          (conversation, _, __, ___, ____, _____, em) =>
              _baseConversationItemOrder(conversation),
          limit);

  Future<bool> _conversationHasData(Expression<bool> predicate) => db.hasData(
      db.conversations,
      [
        innerJoin(db.users, db.conversations.ownerId.equalsExp(db.users.userId),
            useColumns: false)
      ],
      predicate);

  Expression<bool> _chatWhere(Conversations conversation) =>
      conversation.category.isIn(['CONTACT', 'GROUP']);

  Selectable<int> chatConversationCount() => _baseConversationItemCount(
      (conversation, owner, circleConversation) => _chatWhere(conversation));

  Selectable<ConversationItem> chatConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _chatWhere(conversation),
        (_, __, ___, ____, ______, _______, em) => Limit(limit, offset),
      );

  Future<bool> chatConversationHasData() =>
      _conversationHasData(_chatWhere(db.conversations));

  Expression<bool> _contactWhere(Conversations conversation, Users owner) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.relationship.equalsValue(UserRelationship.friend) &
      owner.appId.isNull();

  Selectable<BaseUnseenConversationCountResult> _baseUnseenConversationCount(
          Expression<bool> Function(Conversations conversation, Users owner)
              where) =>
      db.baseUnseenConversationCount((conversation, owner) =>
          conversation.unseenMessageCount.isBiggerThanValue(0) &
          where(conversation, owner));

  Selectable<BaseUnseenConversationCountResult>
      contactUnseenConversationCount() =>
          _baseUnseenConversationCount(_contactWhere);

  Selectable<int> contactConversationCount() => _baseConversationItemCount(
      (conversation, owner, _) => _contactWhere(conversation, owner));

  Selectable<ConversationItem> contactConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _contactWhere(conversation, owner),
        (_, __, ___, ____, ______, _______, em) => Limit(limit, offset),
      );

  Future<bool> contactConversationHasData() =>
      _conversationHasData(_contactWhere(db.conversations, db.users));

  Expression<bool> _strangerWhere(Conversations conversation, Users owner) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.relationship.equalsValue(UserRelationship.stranger) &
      owner.appId.isNull();

  Selectable<BaseUnseenConversationCountResult>
      strangerUnseenConversationCount() =>
          _baseUnseenConversationCount(_strangerWhere);

  Selectable<int> strangerConversationCount() => _baseConversationItemCount(
      (conversation, owner, _) => _strangerWhere(conversation, owner));

  Selectable<ConversationItem> strangerConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _strangerWhere(conversation, owner),
        (_, __, ___, ____, ______, _______, em) => Limit(limit, offset),
      );

  Future<bool> strangerConversationHasData() =>
      _conversationHasData(_strangerWhere(db.conversations, db.users));

  Expression<bool> _groupWhere(Conversations conversation) =>
      conversation.category.equalsValue(ConversationCategory.group);

  Selectable<BaseUnseenConversationCountResult>
      groupUnseenConversationCount() => _baseUnseenConversationCount(
          (conversation, _) => _groupWhere(conversation));

  Selectable<int> groupConversationCount() => _baseConversationItemCount(
      (conversation, _, __) => _groupWhere(conversation));

  Future<bool> groupConversationHasData() =>
      _conversationHasData(_groupWhere(db.conversations));

  Selectable<ConversationItem> groupConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _groupWhere(conversation),
        (
          _,
          __,
          ___,
          ____,
          ______,
          _______,
          ExpiredMessages em,
        ) =>
            Limit(limit, offset),
      );

  Expression<bool> _botWhere(Conversations conversation, Users owner) =>
      conversation.category.equalsValue(ConversationCategory.contact) &
      owner.appId.isNotNull();

  Selectable<BaseUnseenConversationCountResult> botUnseenConversationCount() =>
      _baseUnseenConversationCount(_botWhere);

  Selectable<int> botConversationCount() => _baseConversationItemCount(
      (conversation, owner, _) => _botWhere(conversation, owner));

  Selectable<ConversationItem> botConversations(
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _botWhere(conversation, owner),
        (_, __, ___, ____, ______, _______, em) => Limit(limit, offset),
      );

  Future<bool> botConversationHasData() =>
      _conversationHasData(_botWhere(db.conversations, db.users));

  Selectable<ConversationItem> conversationItem(String conversationId) =>
      _baseConversationItems(
        (conversation, _, __, ___, ____, ______) =>
            conversation.conversationId.equals(conversationId),
        (_, __, ___, ____, ______, _______, em) => Limit(1, null),
      );

  Selectable<ConversationItem> conversationItems() => _baseConversationItems(
        (conversation, _, __, ___, ____, ______) =>
            conversation.category.isIn(['CONTACT', 'GROUP']) &
            conversation.status.equalsValue(ConversationStatus.success),
        (_, __, ___, ____, ______, _______, em) => maxLimit,
      );

  Selectable<int> conversationsCountByCircleId(String circleId) =>
      _baseConversationItemCount((_, __, circleConversation) =>
          circleConversation.circleId.equals(circleId));

  Selectable<ConversationItem> conversationsByCircleId(
          String circleId, int limit, int offset) =>
      db.baseConversationItemsByCircleId(
        circleId,
        (conversation, _, __, ___, ____, _____, _____i, em) =>
            _baseConversationItemOrder(conversation),
        (_, __, ___, ____, ______, _______, ________, em) =>
            Limit(limit, offset),
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

  Future<int> pin(String conversationId) => (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        ConversationsCompanion(pinTime: Value(DateTime.now())),
      );

  Future<int> unpin(String conversationId) async => (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        const ConversationsCompanion(pinTime: Value(null)),
      );

  Future<int> deleteConversation(String conversationId) =>
      (delete(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Future<int> updateConversationStatusById(
      String conversationId, ConversationStatus status) async {
    final already = await db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId) &
            db.conversations.status
                .equals(const ConversationStatusTypeConverter().toSql(status))
                .not());
    if (already) return -1;
    return (db.update(db.conversations)
          ..where((tbl) =>
              tbl.conversationId.equals(conversationId) &
              tbl.status
                  .equals(const ConversationStatusTypeConverter().toSql(status))
                  .not()))
        .write(ConversationsCompanion(status: Value(status)));
  }

  Selectable<SearchConversationItem> fuzzySearchConversation(
          String query, int limit) =>
      db.fuzzySearchConversation(
          query.trim().escapeSql(),
          (Conversations conversation, Users owner, Messages message) =>
              Limit(limit, null));

  Selectable<String?> announcement(String conversationId) =>
      (db.selectOnly(db.conversations)
            ..addColumns([db.conversations.announcement])
            ..where(db.conversations.conversationId.equals(conversationId))
            ..limit(1))
          .map((row) => row.read(db.conversations.announcement));

  Selectable<ConversationStorageUsage> conversationStorageUsage() =>
      db.conversationStorageUsage();

  Future<void> updateConversation(
      ConversationResponse conversation, String currentUserId) {
    var ownerId = conversation.creatorId;
    if (conversation.category == ConversationCategory.contact) {
      ownerId = conversation.participants
          .firstWhere((e) => e.userId != currentUserId)
          .userId;
    }
    return db.transaction(() async {
      await Future.wait([
        insert(
          ConversationsCompanion(
            conversationId: Value(conversation.conversationId),
            ownerId: Value(ownerId),
            category: Value(conversation.category),
            name: Value(conversation.name),
            iconUrl: Value(conversation.iconUrl),
            announcement: Value(conversation.announcement),
            codeUrl: Value(conversation.codeUrl),
            createdAt: Value(conversation.createdAt),
            status: const Value(ConversationStatus.success),
            muteUntil: Value(DateTime.tryParse(conversation.muteUntil)),
            expireIn: Value(conversation.expireIn),
          ),
        ),
        ...conversation.participants.map(
          (participant) => db.participantDao.insert(
            Participant(
              conversationId: conversation.conversationId,
              userId: participant.userId,
              createdAt: participant.createdAt ?? DateTime.now(),
              role: participant.role,
            ),
          ),
        ),
        ...(conversation.participantSessions ?? [])
            .map((p) => db.participantSessionDao.insert(
                  ParticipantSessionData(
                    conversationId: conversation.conversationId,
                    userId: p.userId,
                    sessionId: p.sessionId,
                    publicKey: p.publicKey,
                  ),
                ))
      ]);
    });
  }

  Future<int> updateCodeUrl(String conversationId, String codeUrl) async {
    final already = await db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId) &
            db.conversations.codeUrl.equals(codeUrl));
    if (already) return -1;
    return (update(db.conversations)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .write(ConversationsCompanion(codeUrl: Value(codeUrl)));
  }

  Future<int> updateMuteUntil(String conversationId, String muteUntil) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(
              muteUntil: Value(DateTime.tryParse(muteUntil))));

  Future<int> updateDraft(String conversationId, String draft) async {
    final already = await db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId) &
            db.conversations.draft.equals(draft));

    if (already) return -1;

    return (update(db.conversations)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .write(ConversationsCompanion(draft: Value(draft)));
  }

  Future<bool> hasConversation(String conversationId) => db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId),
      );

  Selectable<GroupMinimal> findTheSameConversations(
          String selfId, String userId) =>
      db.findSameConversations(selfId, userId);

  Future<int> updateConversationExpireIn(String conversationId, int expireIn) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(expireIn: Value(expireIn)));

  Future<EncryptCategory> getEncryptCategory(
      String ownerId, bool isBotConversation) async {
    final app = await db.appDao.findAppById(ownerId);
    if (app != null && app.isEncrypted) {
      return EncryptCategory.encrypted;
    }
    return isBotConversation ? EncryptCategory.plain : EncryptCategory.signal;
  }
}
