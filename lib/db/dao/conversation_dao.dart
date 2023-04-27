import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart'
    hide User, Conversation;

import '../../enum/encrypt_category.dart';
import '../../ui/home/bloc/slide_category_cubit.dart';
import '../../utils/extension/extension.dart';
import '../converter/conversation_status_type_converter.dart';
import '../converter/millis_date_converter.dart';
import '../database_event_bus.dart';
import '../mixin_database.dart';
import '../util/util.dart';
import 'app_dao.dart';
import 'participant_dao.dart';

part 'conversation_dao.g.dart';

@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<MixinDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  late Stream<int> allUnseenIgnoreMuteMessageCountEvent = DataBaseEventBus
      .instance.updateConversationIdStream
      .asyncMap((event) => allUnseenIgnoreMuteMessageCount().getSingle());

  Selectable<int> allUnseenIgnoreMuteMessageCount() =>
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

  Future<int> insert(Conversation conversation) =>
      into(db.conversations).insertOnConflictUpdate(conversation).then((value) {
        if (value > 0) {
          DataBaseEventBus.instance
              .updateConversation(conversation.conversationId);
        }

        return value;
      });

  Selectable<Conversation?> conversationById(String conversationId) =>
      (select(db.conversations)
        ..where((tbl) => tbl.conversationId.equals(conversationId)));

  OrderBy _baseConversationItemOrder(Conversations conversation) => OrderBy(
        [
          OrderingTerm.desc(conversation.pinTime),
          OrderingTerm.desc(
              conversation.status.equalsValue(ConversationStatus.quit).not() &
                  conversation.draft.isNotNull() &
                  conversation.draft.length.isBiggerThanValue(0)),
          OrderingTerm.desc(conversation.lastMessageCreatedAt),
          OrderingTerm.desc(conversation.createdAt),
        ],
      );

  Selectable<int> _baseConversationItemCount(
    BaseConversationItemCount$where where,
  ) =>
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
          Limit limit) =>
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
        (_, __, ___, ____, ______, _______, em) => limit,
      );

  Expression<bool> _conversationPredicateByCategory(SlideCategoryType category,
      [Conversations? conversation, Users? owner]) {
    final Expression<bool> predicate;
    conversation ??= db.conversations;
    owner ??= db.users;
    switch (category) {
      case SlideCategoryType.chats:
        predicate = conversation.category.isIn(['CONTACT', 'GROUP']);
        break;
      case SlideCategoryType.contacts:
        predicate =
            conversation.category.equalsValue(ConversationCategory.contact) &
                owner.relationship.equalsValue(UserRelationship.friend) &
                owner.appId.isNull();
        break;
      case SlideCategoryType.groups:
        predicate =
            conversation.category.equalsValue(ConversationCategory.group);
        break;
      case SlideCategoryType.bots:
        predicate =
            conversation.category.equalsValue(ConversationCategory.contact) &
                owner.appId.isNotNull();
        break;
      case SlideCategoryType.strangers:
        predicate =
            conversation.category.equalsValue(ConversationCategory.contact) &
                owner.relationship.equalsValue(UserRelationship.stranger) &
                owner.appId.isNull();
        break;
      case SlideCategoryType.circle:
      case SlideCategoryType.setting:
        throw UnsupportedError('Unsupported category: $category');
    }
    return predicate;
  }

  Future<bool> conversationHasDataByCategory(SlideCategoryType category) =>
      _conversationHasData(_conversationPredicateByCategory(category));

  Future<int> conversationCountByCategory(SlideCategoryType category) =>
      _baseConversationItemCount((conversation, owner, circle) =>
              _conversationPredicateByCategory(category, conversation, owner))
          .getSingle();

  Future<List<ConversationItem>> conversationItemsByCategory(
    SlideCategoryType category,
    int limit,
    int offset,
  ) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _conversationPredicateByCategory(category, conversation, owner),
        Limit(limit, offset),
      ).get();

  Selectable<ConversationItem> unseenConversationByCategory(
          SlideCategoryType category) =>
      _baseConversationItems(
        (conversation, owner, message, lastMessageSender, snapshot,
                participant) =>
            _conversationPredicateByCategory(category, conversation, owner) &
            conversation.unseenMessageCount.isBiggerThanValue(0),
        maxLimit,
      );

  Future<bool> _conversationHasData(Expression<bool> predicate) => db.hasData(
      db.conversations,
      [
        innerJoin(db.users, db.conversations.ownerId.equalsExp(db.users.userId),
            useColumns: false)
      ],
      predicate);

  Selectable<BaseUnseenConversationCountResult> _baseUnseenConversationCount(
          Expression<bool> Function(Conversations conversation, Users owner)
              where) =>
      db.baseUnseenConversationCount((conversation, owner) =>
          conversation.unseenMessageCount.isBiggerThanValue(0) &
          where(conversation, owner));

  Selectable<BaseUnseenConversationCountResult>
      unseenConversationCountByCategory(SlideCategoryType category) =>
          _baseUnseenConversationCount((conversation, owner) =>
              _conversationPredicateByCategory(category, conversation, owner));

  Selectable<ConversationItem> conversationItem(String conversationId) =>
      _baseConversationItems(
        (conversation, _, __, ___, ____, ______) =>
            conversation.conversationId.equals(conversationId),
        Limit(1, null),
      );

  Selectable<ConversationItem> conversationItems() => _baseConversationItems(
        (conversation, _, __, ___, ____, ______) =>
            conversation.category.isIn(['CONTACT', 'GROUP']) &
            conversation.status.equalsValue(ConversationStatus.success),
        maxLimit,
      );

  Selectable<int> conversationsCountByCircleId(String circleId) =>
      _baseConversationItemCount((_, __, circleConversation) =>
          circleConversation.circleId.equals(circleId));

  Selectable<ConversationItem> conversationsByCircleId(
          String circleId, int limit, int offset) =>
      db.baseConversationItemsByCircleId(
        (conversation, o, circleConversation, lm, ls, s, p, em) =>
            circleConversation.circleId.equals(circleId),
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

  Selectable<ConversationItem> unseenConversationsByCircleId(String circleId) =>
      db.baseConversationItemsByCircleId(
        (conversation, o, circleConversation, lm, ls, s, p, em) =>
            circleConversation.circleId.equals(circleId) &
            conversation.unseenMessageCount.isBiggerThanValue(0),
        (conversation, _, __, ___, ____, _____, _____i, em) =>
            _baseConversationItemOrder(conversation),
        (_, __, ___, ____, ______, _______, ________, em) => maxLimit,
      );

  Future<int> pin(String conversationId) => (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        ConversationsCompanion(pinTime: Value(DateTime.now())),
      )
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });

  Future<int> unpin(String conversationId) => (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(
        const ConversationsCompanion(pinTime: Value(null)),
      )
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });

  Future<int> deleteConversation(String conversationId) =>
      (delete(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go()
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });

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
        .write(ConversationsCompanion(status: Value(status)))
        .then((value) {
      if (value > 0) {
        DataBaseEventBus.instance.updateConversation(conversationId);
      }
      return value;
    });
  }

  Selectable<SearchConversationItem> fuzzySearchConversation(
    String query,
    int limit, {
    bool filterUnseen = false,
    SlideCategoryState? category,
  }) {
    if (category?.type == SlideCategoryType.circle) {
      return db.fuzzySearchConversationInCircle(
        query.trim().escapeSql(),
        category!.id,
        (conversation, owner, message, _, cc, __) => filterUnseen
            ? conversation.unseenMessageCount.isBiggerThanValue(0)
            : ignoreWhere,
        (conversation, owner, message, _, cc, __) => Limit(limit, null),
      );
    }
    return db.fuzzySearchConversation(query.trim().escapeSql(),
        (Conversations conversation, Users owner, Messages message, _, __) {
      Expression<bool> predicate = ignoreWhere;
      switch (category?.type) {
        case SlideCategoryType.contacts:
        case SlideCategoryType.groups:
        case SlideCategoryType.bots:
        case SlideCategoryType.strangers:
          predicate = _conversationPredicateByCategory(
              category!.type, conversation, owner);
          break;

        case SlideCategoryType.circle:
        case SlideCategoryType.setting:
          assert(false, 'Invalid category type: ${category!.type}');
          break;
        case null:
        case SlideCategoryType.chats:
          break;
      }
      if (filterUnseen) {
        predicate &= conversation.unseenMessageCount.isBiggerThanValue(0);
      }
      return predicate;
    },
        (Conversations conversation, Users owner, Messages message, _, __) =>
            Limit(limit, null));
  }

  Selectable<SearchConversationItem> searchConversationItemByIn(
          List<String> ids) =>
      db.searchConversationItemByIn(ids, (conversation, _, __, ___, ____) {
        if (ids.isEmpty) return ignoreOrderBy;

        final conversationId =
            '${conversation.aliasedName}.${conversation.conversationId.$name}';

        return OrderBy([
          OrderingTerm.desc(CustomExpression(
              'CASE $conversationId ${ids.asMap().entries.map((e) => "WHEN '${e.value}' THEN ${e.key}").join(' ')} END'))
        ]);
      });

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
          Conversation(
            conversationId: conversation.conversationId,
            ownerId: ownerId,
            category: conversation.category,
            name: conversation.name,
            iconUrl: conversation.iconUrl,
            announcement: conversation.announcement,
            codeUrl: conversation.codeUrl,
            createdAt: conversation.createdAt,
            status: ConversationStatus.success,
            muteUntil: DateTime.tryParse(conversation.muteUntil),
            expireIn: conversation.expireIn,
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
    }).then((value) {
      DataBaseEventBus.instance.updateConversation(conversation.conversationId);
      DataBaseEventBus.instance.updateParticipant(conversation.participants.map(
          (p) => MiniParticipantItem(
              conversationId: conversation.conversationId, userId: p.userId)));
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
        .write(ConversationsCompanion(codeUrl: Value(codeUrl)))
        .then((value) {
      if (value > 0) {
        DataBaseEventBus.instance.updateConversation(conversationId);
      }
      return value;
    });
  }

  Future<int> updateMuteUntil(String conversationId, String muteUntil) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(
              muteUntil: Value(DateTime.tryParse(muteUntil))))
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });

  Future<int> updateDraft(String conversationId, String draft) async {
    final already = await db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId) &
            db.conversations.draft.equals(draft));

    if (already) return -1;

    return (update(db.conversations)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .write(ConversationsCompanion(draft: Value(draft)))
        .then((value) {
      if (value > 0) {
        DataBaseEventBus.instance.updateConversation(conversationId);
      }

      return value;
    });
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
          .write(ConversationsCompanion(expireIn: Value(expireIn)))
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });

  Future<EncryptCategory> getEncryptCategory(
      String ownerId, bool isBotConversation) async {
    final app = await db.appDao.findAppById(ownerId);
    if (app != null && app.isEncrypted) {
      return EncryptCategory.encrypted;
    }
    return isBotConversation ? EncryptCategory.plain : EncryptCategory.signal;
  }

  Future<List<Conversation>> getConversations({
    required int limit,
    required int offset,
  }) =>
      (select(db.conversations)
            ..orderBy([
              (c) => OrderingTerm.asc(c.rowId),
            ])
            ..limit(limit, offset: offset))
          .get();

  Future<int> updateLastSentMessage(
    String conversationId,
    String messageId,
    DateTime createdAt,
  ) =>
      (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(
        lastMessageId: Value(messageId),
        lastMessageCreatedAt: Value(createdAt),
        draft: const Value(''),
      ))
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });

  Future<int> updateUnseenMessageCountAndLastMessageId(
    String conversationId,
    String userId,
    String? lastMessageId,
    DateTime? lastMessageCreatedAt,
  ) =>
      db
          .updateUnseenMessageCountAndLastMessageId(
        conversationId,
        userId,
        lastMessageId,
        lastMessageCreatedAt,
      )
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }
        return value;
      });
}
