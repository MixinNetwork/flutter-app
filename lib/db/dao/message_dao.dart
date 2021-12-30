import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../utils/extension/extension.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../database_event_bus.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<MixinDatabase>
    with _$MessageDaoMixin {
  MessageDao(MixinDatabase db) : super(db);

  late Stream<void> updateEvent = db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.messages,
      db.users,
      db.snapshots,
      db.assets,
      db.stickers,
      db.hyperlinks,
      db.messageMentions,
      db.conversations,
    ]),
  );

  late Stream<void> searchMessageUpdateEvent = db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          db.messages,
          db.users,
          db.conversations,
          db.messagesFts,
        ]),
      )
      .throttleTime(kDefaultThrottleDuration, trailing: true);

  late Stream<List<MessageItem>> insertOrReplaceMessageStream = db.eventBus
      .watch<Iterable<String>>(DatabaseEvent.insertOrReplaceMessage)
      .asyncBufferMap(
    (event) {
      final ids =
          event.reduce((value, element) => [...value, ...element]).toSet();
      return _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.messageId.isIn(ids),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(ids.length, 0)).get();
    },
  );

  late Stream<NotificationMessage> notificationMessageStream = db.eventBus
      .watch<String>(DatabaseEvent.notification)
      .asyncBufferMap((event) => db.notificationMessage(event).get())
      .flatMapIterable((value) => Stream.value(value));

  late Stream<String> deleteMessageIdStream =
      db.eventBus.watch<String>(DatabaseEvent.delete);

  Selectable<MessageItem> _baseMessageItems(
    Expression<bool?> Function(
      Messages message,
      Users sender,
      Users participant,
      Snapshots snapshot,
      Assets asset,
      Stickers sticker,
      Hyperlinks hyperlink,
      Users sharedUser,
      Conversations conversation,
      MessageMentions messageMention,
      PinMessages pinMessage,
    )
        where,
    Limit Function(
      Messages message,
      Users sender,
      Users participant,
      Snapshots snapshot,
      Assets asset,
      Stickers sticker,
      Hyperlinks hyperlink,
      Users sharedUser,
      Conversations conversation,
      MessageMentions messageMention,
      PinMessages pinMessage,
    )
        limit, {
    OrderBy Function(
      Messages message,
      Users sender,
      Users participant,
      Snapshots snapshot,
      Assets asset,
      Stickers sticker,
      Hyperlinks hyperlink,
      Users sharedUser,
      Conversations conversation,
      MessageMentions messageMention,
      PinMessages pinMessage,
    )?
        order,
  }) =>
      db.baseMessageItems(
          where,
          (message, sender, participant, snapshot, asset, sticker, hyperlink,
                  sharedUser, conversation, messageMention, pinMessage) =>
              order?.call(
                  message,
                  sender,
                  participant,
                  snapshot,
                  asset,
                  sticker,
                  hyperlink,
                  sharedUser,
                  conversation,
                  messageMention,
                  pinMessage) ??
              OrderBy([OrderingTerm.desc(message.createdAt)]),
          limit);

  Future<T> _sendInsertOrReplaceEventWithFuture<T>(
    List<String> messageIds,
    Future<T> future,
  ) async {
    final result = await future;
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, messageIds);
    return result;
  }

  final Map<String, void Function()> _conversationUnseenTaskRunner = {};

  // TODO maybe more effective?
  void _updateConversationUnseenCount(
    Message message,
    String currentUserId,
  ) {
    Future<void> _update(Message message) async {
      final unseenMessageCount = await _getUnseenMessageCount(
        userId: currentUserId,
        conversationId: message.conversationId,
      );
      final unseen = message.userId != currentUserId &&
              [MessageStatus.sent, MessageStatus.delivered]
                  .contains(message.status)
          ? 1
          : 0;
      await db.conversationDao.updateLastMessageId(
        message.conversationId,
        message.messageId,
        message.createdAt,
        unseenMessageCount + unseen,
      );
    }

    if (_conversationUnseenTaskRunner[message.conversationId] != null) {
      _conversationUnseenTaskRunner[message.conversationId] =
          () => _update(message);
      return;
    } else {
      _conversationUnseenTaskRunner[message.conversationId] =
          () => _update(message);
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        final runner =
            _conversationUnseenTaskRunner.remove(message.conversationId);
        runner?.call();
      });
    }
  }

  Future<int> insert(Message message, String currentUserId,
      [bool? silent = false]) async {
    final result = await db.transaction(() async {
      final futures = <Future>[
        into(db.messages).insertOnConflictUpdate(message),
        _insertMessageFts(message),
      ];
      return (await Future.wait(futures))[0] as int;
    });

    _updateConversationUnseenCount(message, currentUserId);

    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [message.messageId]);
    if (!(silent ?? false)) {
      db.eventBus.send(DatabaseEvent.notification, message.messageId);
    }

    return result;
  }

  Future<void> _insertMessageFts(Message message) async {
    String? ftsContent;
    if (message.category.isText || message.category.isPost) {
      ftsContent = message.content;
    } else if (message.category.isData) {
      ftsContent = message.name;
    } else if (message.category.isContact) {
      ftsContent = message.name;
    } else if (message.category == MessageCategory.appCard) {
      final appCard = AppCardData.fromJson(
          jsonDecode(message.content!) as Map<String, dynamic>);
      ftsContent = '${appCard.title} ${appCard.description}';
    }
    if (ftsContent != null) {
      await insertFts(
        message.messageId,
        message.conversationId,
        ftsContent.joinWhiteSpace(),
        message.createdAt,
        message.userId,
      );
    }
  }

  Future<int> insertFts(String messageId, String conversationId, String content,
          DateTime createdAt, String userId) =>
      db.customInsert(
        "INSERT OR REPLACE INTO messages_fts (message_id, conversation_id, content, created_at, user_id) VALUES ('$messageId', '$conversationId','${content.escapeSqliteSingleQuotationMarks()}', '${createdAt.millisecondsSinceEpoch}', '$userId')",
        updates: {db.messagesFts},
      );

  Future<void> deleteMessage(String messageId) async {
    await db.transaction(() async {
      await Future.wait([
        (delete(db.messages)..where((tbl) => tbl.messageId.equals(messageId)))
            .go(),
        (delete(db.messagesFts)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .go(),
        (delete(db.transcriptMessages)
              ..where((tbl) => tbl.transcriptId.equals(messageId)))
            .go(),
        _recallPinMessage(messageId),
        db.pinMessageDao.deleteByIds([messageId]),
      ]);
    });
    db.eventBus.send(DatabaseEvent.delete, messageId);
  }

  Future<void> deleteMessageByConversationId(String conversationId) =>
      (delete(db.messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Future<SendingMessage?> sendingMessage(String messageId) async =>
      db.sendingMessage(messageId).getSingleOrNull();

  Future<int> updateMessageStatusById(String messageId, MessageStatus status) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(status: Value(status))),
      );

  Future<MessageStatus?> findMessageStatusById(String messageId) =>
      db.findMessageStatusById(messageId).getSingleOrNull();

  Future<void> updateMedia({
    required String path,
    required String messageId,
    required int mediaSize,
    required MediaStatus mediaStatus,
    String? content,
  }) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.transaction(() async {
          await Future.wait([
            (db.update(db.messages)
                  ..where((tbl) => tbl.messageId.equals(messageId)))
                .write(MessagesCompanion(
              mediaUrl: Value(path.pathBasename),
              mediaSize: Value(mediaSize),
              mediaStatus: Value(mediaStatus),
            )),
            (db.update(db.transcriptMessages)
                  ..where((tbl) => tbl.messageId.equals(messageId)))
                .write(TranscriptMessagesCompanion(
              mediaUrl: Value(path.pathBasename),
              mediaSize: Value(mediaSize),
              mediaStatus: Value(mediaStatus),
              content: content != null ? Value(content) : const Value.absent(),
            )),
          ]);
        }),
      );

  Future<void> updateMediaStatus(String messageId, MediaStatus status) async {
    if (await hasMediaStatus(messageId, status)) return;

    final result = await db.transaction<List>(() => Future.wait([
          (db.update(db.messages)
                ..where((tbl) => tbl.messageId.equals(messageId)))
              .write(MessagesCompanion(mediaStatus: Value(status))),
          (db.update(db.transcriptMessages)
                ..where((tbl) => tbl.messageId.equals(messageId)))
              .write(TranscriptMessagesCompanion(mediaStatus: Value(status))),
        ]));
    if (result.cast<int>().any((element) => element > -1)) {
      db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
    }
  }

  Future<bool?> messageHasMediaStatus(String messageId, MediaStatus mediaStatus,
      [bool not = false]) async {
    final mediaStatusColumn = db.messages.mediaStatus;
    final _mediaStatus = await (selectOnly(db.messages)
          ..addColumns([mediaStatusColumn])
          ..where(db.messages.messageId.equals(messageId))
          ..limit(1))
        .map((row) =>
            mediaStatusColumn.converter.mapToDart(row.read(mediaStatusColumn)))
        .getSingleOrNull();
    if (_mediaStatus == null) return null;
    if (not) {
      return _mediaStatus != mediaStatus;
    }
    return _mediaStatus == mediaStatus;
  }

  Future<bool?> transcriptMessageHasMediaStatus(
      String messageId, MediaStatus mediaStatus,
      [bool not = false]) async {
    final mediaStatusColumn = db.transcriptMessages.mediaStatus;
    final _mediaStatus = await (selectOnly(db.transcriptMessages)
          ..addColumns([mediaStatusColumn])
          ..where(db.transcriptMessages.messageId.equals(messageId))
          ..limit(1))
        .map((row) =>
            mediaStatusColumn.converter.mapToDart(row.read(mediaStatusColumn)))
        .getSingleOrNull();
    if (_mediaStatus == null) return null;
    if (not) {
      return _mediaStatus != mediaStatus;
    }
    return _mediaStatus == mediaStatus;
  }

  Future<bool> hasMediaStatus(String messageId, MediaStatus mediaStatus,
      [bool not = false]) async {
    final messageHasData =
        await messageHasMediaStatus(messageId, mediaStatus, not);
    final transcriptMessageHasData =
        await transcriptMessageHasMediaStatus(messageId, mediaStatus, not);
    if (messageHasData != null && transcriptMessageHasData != null) {
      return messageHasData && transcriptMessageHasData;
    }
    return (messageHasData ?? false) || (transcriptMessageHasData ?? false);
  }

  Future<void> syncMessageMedia(String messageId, [bool force = false]) async {
    if (!force && !await hasMediaStatus(messageId, MediaStatus.done)) {
      return;
    }

    var content = db.messages.content;
    var mediaUrl = db.messages.mediaUrl;
    var mediaSize = db.messages.mediaSize;
    var mediaStatus = db.messages.mediaStatus;

    var result = await (db.selectOnly(db.messages)
          ..addColumns([content, mediaUrl, mediaSize, mediaStatus])
          ..where(db.messages.messageId.equals(messageId))
          ..limit(1))
        .getSingleOrNull();
    if (result == null) {
      content = db.transcriptMessages.content;
      mediaUrl = db.transcriptMessages.mediaUrl;
      mediaSize = db.transcriptMessages.mediaSize;
      mediaStatus = db.transcriptMessages.mediaStatus;

      result = await (db.selectOnly(db.transcriptMessages)
            ..addColumns([content, mediaUrl, mediaSize, mediaStatus])
            ..where(db.transcriptMessages.messageId.equals(messageId))
            ..limit(1))
          .getSingleOrNull();
    }

    if (result == null) return;

    await updateMedia(
      path: result.read(mediaUrl)!,
      messageId: messageId,
      mediaSize: result.read(mediaSize)!,
      mediaStatus: mediaStatus.converter.mapToDart(result.read(mediaStatus))!,
      content: result.read(content),
    );
  }

  Future<int> _getUnseenMessageCount({
    required String conversationId,
    required String userId,
  }) async {
    final count = db.messages.messageId.count();
    final status = db.messages.status;
    return (await (db.selectOnly(db.messages)
              ..addColumns([count])
              ..where(
                db.messages.conversationId.equals(conversationId) &
                    db.messages.userId.equals(userId).not() &
                    status.isIn(
                      [MessageStatus.sent, MessageStatus.delivered]
                          .map(status.converter.mapToSql),
                    ),
              )
              ..limit(1))
            .map((row) => row.read(count))
            .getSingleOrNull()) ??
        0;
  }

  Future<int> takeUnseen(String userId, String conversationId) async {
    final messageId = await (db.selectOnly(db.messages)
          ..addColumns([db.messages.messageId])
          ..where(db.messages.conversationId.equals(conversationId) &
              db.messages.status.equalsValue(MessageStatus.read))
          ..orderBy([
            OrderingTerm(
                expression: db.messages.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .map((row) => row.read(db.messages.messageId))
        .getSingleOrNull();

    return db.customUpdate(
      "UPDATE conversations SET last_read_message_id = ?, unseen_message_count = (SELECT count(1) FROM messages m WHERE m.conversation_id = ? AND m.user_id != ? AND m.status IN ('SENT', 'DELIVERED')) WHERE conversation_id = ?",
      variables: [
        Variable(messageId),
        Variable.withString(conversationId),
        Variable.withString(userId),
        Variable.withString(conversationId)
      ],
      updates: {db.conversations},
      updateKind: UpdateKind.update,
    );
  }

  Future<int> markMessageRead(
    String userId,
    Iterable<String> messageIds,
  ) async {
    final result = await (db.update(db.messages)
          ..where((tbl) =>
              tbl.messageId.isIn(messageIds) &
              tbl.status.equalsValue(MessageStatus.failed).not() &
              tbl.status.equalsValue(MessageStatus.unknown).not()))
        .write(const MessagesCompanion(status: Value(MessageStatus.read)));
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, messageIds);
    return result;
  }

  Future<List<String>> findConversationIdsByMessages(
      List<String> messageIds) async {
    final future = await (db.selectOnly(db.messages, distinct: true)
          ..addColumns([db.messages.conversationId])
          ..where(db.messages.messageId.isIn(messageIds)))
        .map((row) => row.read(db.messages.conversationId))
        .get();
    return future.whereNotNull().toList();
  }

  Selectable<MessageItem> messagesByConversationId(
    String conversationId,
    int limit, [
    int offset = 0,
  ]) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, offset));

  Selectable<int> messageCountByConversationId(String conversationId) {
    final countExp = countAll();
    return (db.selectOnly(db.messages)
          ..addColumns([countExp])
          ..where(db.messages.conversationId.equals(conversationId)))
        .map(
      (row) => row.read(countExp),
    );
  }

  Future<List<String>> getUnreadMessageIds(
          String conversationId, String userId) =>
      db.transaction(() async {
        final list = await (db.selectOnly(db.messages)
              ..addColumns([db.messages.messageId])
              ..where(db.messages.conversationId.equals(conversationId) &
                  db.messages.userId.equals(userId).not() &
                  db.messages.status.isIn(['SENT', 'DELIVERED'])))
            .map((row) => row.read(db.messages.messageId))
            .get();
        final ids = list.whereNotNull().toList();
        if (ids.isNotEmpty) {
          await markMessageRead(userId, ids);
        }
        await takeUnseen(userId, conversationId);
        return ids;
      });

  Future<QuoteMessageItem?> findMessageItemById(
          String conversationId, String messageId) =>
      db
          .baseQuoteMessageItem(
              (message, sender, sticker, shareUser, messageMention) =>
                  message.conversationId.equals(conversationId) &
                  message.messageId.equals(messageId) &
                  message.status.equalsValue(MessageStatus.failed).not(),
              (message, sender, sticker, shareUser, messageMention) =>
                  ignoreOrderBy,
              (message, sender, sticker, shareUser, messageMention) =>
                  Limit(1, 0))
          .getSingleOrNull();

  Future<QuoteMessageItem?> findMessageItemByMessageId(
      String? messageId) async {
    if (messageId == null) return null;
    return db
        .baseQuoteMessageItem(
            (message, sender, sticker, shareUser, messageMention) =>
                message.messageId.equals(messageId) &
                message.status.equalsValue(MessageStatus.failed).not(),
            (message, sender, sticker, shareUser, messageMention) =>
                ignoreOrderBy,
            (message, sender, sticker, shareUser, messageMention) =>
                Limit(1, 0))
        .getSingleOrNull();
  }

  Future<Message?> findMessageByMessageId(String messageId) =>
      (db.select(db.messages)
            ..where((tbl) => tbl.messageId.equals(messageId))
            ..limit(1))
          .getSingleOrNull();

  Future<String?> findMessageIdByMessageId(String messageId) =>
      (db.selectOnly(db.messages)
            ..addColumns([db.messages.messageId])
            ..where(db.messages.messageId.equals(messageId)))
          .map((row) => row.read(db.messages.messageId))
          .getSingleOrNull();

  Future<Message?> findMessageByMessageIdAndUserId(
          String messageId, String userId) =>
      (select(db.messages)
            ..where(
                (r) => r.messageId.equals(messageId) & r.userId.equals(userId)))
          .getSingleOrNull();

  Future<List<String>> findFailedMessages(
          String conversationId, String userId) async =>
      (db.selectOnly(db.messages)
            ..addColumns([db.messages.messageId])
            ..where(db.messages.conversationId.equals(conversationId) &
                db.messages.userId.equals(userId) &
                db.messages.status.equalsValue(MessageStatus.failed))
            ..orderBy([OrderingTerm.desc(db.messages.createdAt)])
            ..limit(1000))
          .map((row) {
        final string = row.read(db.messages.messageId);
        assert(string != null);
        return string!;
      }).get();

  Future<int> countMessageByQuoteId(String conversationId, String messageId) =>
      (db.selectOnly(db.messages)
            ..addColumns([db.messages.messageId.count()])
            ..where(db.messages.conversationId.equals(conversationId) &
                db.messages.quoteMessageId.equals(messageId) &
                db.messages.quoteContent.isNull()))
          .map((row) => row.read(db.messages.messageId.count()))
          .getSingle();

  Future<int> updateQuoteContentByQuoteId(
      String conversationId, String quoteMessageId, String content) async {
    final messageIds = await _findMessageIdByQuoteMessageId(quoteMessageId);
    return _sendInsertOrReplaceEventWithFuture(
        messageIds,
        (db.update(db.messages)
              ..where((tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.quoteMessageId.equals(quoteMessageId)))
            .write(MessagesCompanion(quoteContent: Value(content))));
  }

  Future<List<String>> _findMessageIdByQuoteMessageId(
      String quoteMessageId) async {
    final future = await (db.selectOnly(db.messages, distinct: true)
          ..addColumns([db.messages.messageId])
          ..where(db.messages.quoteMessageId.equals(quoteMessageId)))
        .map((row) => row.read(db.messages.messageId))
        .get();
    return future.whereNotNull().toList();
  }

  Future<int> updateAttachmentMessageContentAndStatus(
          String messageId, String content) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(
          mediaStatus: const Value(MediaStatus.done),
          status: const Value(MessageStatus.sending),
          content: Value(content),
        )),
      );

  Future<void> updateMessageContent(String messageId, String content) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.transaction(() async {
          await Future.wait([
            (db.update(db.messages)
                  ..where((tbl) => tbl.messageId.equals(messageId)))
                .write(MessagesCompanion(content: Value(content))),
            (db.update(db.transcriptMessages)
                  ..where((tbl) => tbl.messageId.equals(messageId)))
                .write(TranscriptMessagesCompanion(content: Value(content))),
          ]);
        }),
      );

  Future<int> updateMessageContentAndStatus(
          String messageId, String content, MessageStatus status) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) =>
                  tbl.messageId.equals(messageId) &
                  tbl.category.equals(MessageCategory.messageRecall).not()))
            .write(MessagesCompanion(
          content: Value(content),
          status: Value(status),
        )),
      );

  Future<int> updateAttachmentMessage(
          String messageId, MessagesCompanion messagesCompanion) async =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (update(db.messages)..where((t) => t.messageId.equals(messageId)))
            .write(messagesCompanion),
      );

  Future<int> updateStickerMessage(
          String messageId, MessageStatus status, String stickerId) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) =>
                  tbl.messageId.equals(messageId) &
                  tbl.category.equals(MessageCategory.messageRecall).not()))
            .write(MessagesCompanion(
          stickerId: Value(stickerId),
          status: Value(status),
        )),
      );

  Future<int> updateContactMessage(
          String messageId, MessageStatus status, String sharedUserId) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) =>
                  tbl.messageId.equals(messageId) &
                  tbl.category.equals(MessageCategory.messageRecall).not()))
            .write(MessagesCompanion(
          sharedUserId: Value(sharedUserId),
          status: Value(status),
        )),
      );

  Future<int> updateLiveMessage(String messageId, int width, int height,
          String url, String thumbUrl, MessageStatus status) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) =>
                  tbl.messageId.equals(messageId) &
                  tbl.category.equals(MessageCategory.signalLive).not()))
            .write(MessagesCompanion(
          mediaWidth: Value(width),
          mediaHeight: Value(height),
          mediaUrl: Value(url),
          thumbUrl: Value(thumbUrl),
          status: Value(status),
        )),
      );

  Selectable<MessageItem> mediaMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_IMAGE', 'PLAIN_IMAGE']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, offset));

  Selectable<MessageItem> mediaMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId') &
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_IMAGE', 'PLAIN_IMAGE']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, 0));

  Selectable<MessageItem> mediaMessagesAfter(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid > $rowId') &
              message.category.isIn(['SIGNAL_IMAGE', 'PLAIN_IMAGE']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              OrderBy([OrderingTerm.asc(message.createdAt)]));

  Selectable<MessageItem> postMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_POST', 'PLAIN_POST']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, offset));

  Selectable<MessageItem> postMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId') &
              message.category.isIn(['SIGNAL_POST', 'PLAIN_POST']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, 0));

  Selectable<MessageItem> fileMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_DATA', 'PLAIN_DATA']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, offset));

  Selectable<MessageItem> fileMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId') &
              message.category.isIn(['SIGNAL_DATA', 'PLAIN_DATA']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, 0));

  Selectable<MessageItem> beforeMessagesByConversationId(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId'),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, 0));

  Selectable<MessageItem> afterMessagesByConversationId(
          int rowId, String conversationId, int limit,
          {bool orEqual = false}) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>(
                  '${message.aliasedName}.rowid >${orEqual ? '=' : ''} $rowId'),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              OrderBy([OrderingTerm.asc(message.createdAt)]));

  Selectable<MessageItem> messageItemByMessageId(
          String messageId) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________) =>
              message.messageId.equals(messageId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________) =>
              Limit(1, 0));

  Future<MessageItem?> findNextAudioMessageItem({
    required String conversationId,
    required String messageId,
    required DateTime createdAt,
  }) async {
    final rowId = await messageRowId(messageId).getSingleOrNull();
    return _baseMessageItems(
      (message, _, __, ___, ____, _____, ______, _______, conversation,
              ________, _________) =>
          conversation.conversationId.equals(conversationId) &
          message.category.isIn([
            MessageCategory.signalAudio,
            MessageCategory.plainAudio,
            MessageCategory.encryptedAudio
          ]) &
          message.createdAt.isBiggerOrEqualValue(
              message.createdAt.converter.mapToSql(createdAt)) &
          message.rowId.isBiggerThanValue(rowId),
      (_, __, ___, ____, _____, ______, _______, ________, _________,
              __________, ___________) =>
          Limit(1, 0),
      order: (message, _, __, ___, ____, _____, ______, _______, ________,
              _________, __________) =>
          OrderBy([OrderingTerm.asc(message.createdAt)]),
    ).getSingleOrNull();
  }

  Future<void> _recallPinMessage(String messageId) async {
    final messageIds = (await (db.selectOnly(db.messages)
              ..addColumns([db.messages.messageId])
              ..where(db.messages.category.equals(MessageCategory.messagePin) &
                  db.messages.quoteMessageId.equals(messageId)))
            .map((row) => row.read(db.messages.messageId))
            .get())
        .whereNotNull();

    if (messageIds.isEmpty) return;

    await (db.update(db.messages)
          ..where(
            (tbl) => tbl.messageId.isIn(messageIds),
          ))
        .write(const MessagesCompanion(
      content: Value(null),
    ));

    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, messageIds);
  }

  Future<void> recallMessage(String messageId) async {
    await (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(const MessagesCompanion(
      category: Value(MessageCategory.messageRecall),
      status: Value(MessageStatus.read),
      content: Value(null),
      mediaUrl: Value(null),
      mediaMimeType: Value(null),
      mediaSize: Value(null),
      mediaDuration: Value(null),
      mediaWidth: Value(null),
      mediaHeight: Value(null),
      mediaHash: Value(null),
      thumbImage: Value(null),
      mediaKey: Value(null),
      mediaDigest: Value(null),
      mediaStatus: Value(null),
      action: Value(null),
      participantId: Value(null),
      snapshotId: Value(null),
      hyperlink: Value(null),
      name: Value(null),
      albumId: Value(null),
      stickerId: Value(null),
      sharedUserId: Value(null),
      mediaWaveform: Value(null),
      quoteMessageId: Value(null),
      quoteContent: Value(null),
    ));

    await _recallPinMessage(messageId);

    await db.pinMessageDao.deleteByIds([messageId]);
    // Maybe use another event
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
    db.eventBus.send(DatabaseEvent.notification, messageId);
  }

  Selectable<SearchMessageDetailItem> fuzzySearchMessage({
    required String query,
    required int limit,
    int offset = 0,
    String? conversationId,
    String? userId,
    List<String>? categories,
  }) {
    final keywordFts5 = query.trim().escapeFts5();
    if (conversationId != null && userId != null) {
      if (categories != null) {
        return db.fuzzySearchMessageByConversationIdAndUserIdAndCategories(
          conversationId,
          userId,
          categories,
          keywordFts5,
          (_, __, ___) => Limit(limit, offset),
        );
      }

      return db.fuzzySearchMessageByConversationIdAndUserId(
        conversationId,
        userId,
        keywordFts5,
        limit,
        offset,
      );
    }

    if (conversationId != null) {
      if (categories != null) {
        return db.fuzzySearchMessageByConversationIdAndCategories(
          conversationId,
          categories,
          keywordFts5,
          (_, __, ___) => Limit(limit, offset),
        );
      }

      return db.fuzzySearchMessageByConversationId(
        conversationId,
        keywordFts5,
        limit,
        offset,
      );
    }

    if (categories != null) {
      return db.fuzzySearchMessageByCategories(
        keywordFts5,
        categories,
        (_, __, ___) => Limit(limit, offset),
      );
    }

    return db.fuzzySearchMessage(
      keywordFts5,
      limit,
      offset,
    );
  }

  Selectable<int> fuzzySearchMessageCount(
    String keyword, {
    String? conversationId,
    String? userId,
    List<String>? categories,
  }) {
    final keywordFts5 = keyword.trim().escapeFts5();

    if (conversationId != null && userId != null) {
      if (categories != null) {
        return db.fuzzySearchMessageCountByConversationIdAndUserIdAndCategories(
          conversationId,
          userId,
          categories,
          keywordFts5,
        );
      }

      return db.fuzzySearchMessageCountByConversationIdAndUserId(
        conversationId,
        userId,
        keywordFts5,
      );
    }

    // var $ in categories
    if (conversationId != null) {
      if (categories != null) {
        return db.fuzzySearchMessageCountByConversationIdAndCategories(
          conversationId,
          categories,
          keywordFts5,
        );
      }

      return db.fuzzySearchMessageCountByConversationId(
        conversationId,
        keywordFts5,
      );
    }

    if (categories != null) {
      return db.fuzzySearchMessageCountByCategories(keywordFts5, categories);
    }
    return db.fuzzySearchMessageCount(keywordFts5);
  }

  Selectable<SearchMessageDetailItem> fuzzySearchMessageByConversationAndUser({
    required String conversationId,
    required String userId,
    required String query,
    List<String>? categories,
    required int limit,
    int offset = 0,
  }) {
    final keywordFts5 = query.trim().escapeFts5();

    return db.fuzzySearchMessageByConversationIdAndUserId(
      conversationId,
      userId,
      keywordFts5,
      limit,
      offset,
    );
  }

  Selectable<SearchMessageDetailItem> fuzzySearchMessageByConversationId({
    required String conversationId,
    required String query,
    required int limit,
    int offset = 0,
  }) =>
      db.fuzzySearchMessageByConversationId(
        conversationId,
        query.trim().escapeFts5(),
        limit,
        offset,
      );

  Selectable<SearchMessageDetailItem> messageByConversationAndUser({
    required String conversationId,
    required String userId,
    required int limit,
    int offset = 0,
    List<String>? categories,
  }) =>
      db.searchMessage((m, c, u) {
        var predicate =
            m.conversationId.equals(conversationId) & m.userId.equals(userId);
        if (categories?.isNotEmpty ?? false) {
          predicate = predicate & m.category.isIn(categories!);
        }
        return predicate;
      }, (m, c, u) => Limit(limit, offset));

  Selectable<SearchMessageDetailItem>
      fuzzySearchMessageByConversationIdAndUserId({
    required String conversationId,
    required String userId,
    required String query,
    required int limit,
    int offset = 0,
  }) =>
          db.fuzzySearchMessageByConversationIdAndUserId(
            conversationId,
            userId,
            query.trim().escapeFts5(),
            limit,
            offset,
          );

  Selectable<int> messageCountByConversationAndUser(
    String conversationId,
    String userId,
    List<String>? categories,
  ) {
    final countExp = countAll();
    final messages = db.messages;
    var predicate = messages.conversationId.equals(conversationId) &
        messages.userId.equals(userId);
    if (categories?.isNotEmpty ?? false) {
      predicate = predicate & messages.category.isIn(categories!);
    }
    return (db.selectOnly(messages)
          ..addColumns([countExp])
          ..where(predicate))
        .map(
      (row) => row.read(countExp),
    );
  }

  Selectable<int?> messageRowId(String messageId) => (selectOnly(db.messages)
        ..addColumns([db.messages.rowId])
        ..where(db.messages.messageId.equals(messageId))
        ..limit(1))
      .map((row) => row.read(db.messages.rowId));

  Future<int> deleteFtsByMessageId(String messageId) =>
      (db.delete(db.messagesFts)
            ..where((tbl) => tbl.messageId.equals(messageId)))
          .go();

  Future<int> updateTranscriptMessage(
    String? content,
    int? mediaSize,
    MediaStatus? mediaStatus,
    MessageStatus status,
    String messageId,
  ) =>
      _sendInsertOrReplaceEventWithFuture(
          [messageId],
          (db.update(db.messages)
                ..where((tbl) =>
                    tbl.messageId.equals(messageId) &
                    tbl.category.equals('SIGNAL_TRANSCRIPT').not()))
              .write(MessagesCompanion(
            content: Value(content),
            mediaSize: Value(mediaSize),
            mediaStatus: Value(mediaStatus),
            status: Value(status),
            messageId: Value(messageId),
          )));

  void notifyMessageInsertOrReplaced(Iterable<String> messageIds) =>
      db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, messageIds);
}
