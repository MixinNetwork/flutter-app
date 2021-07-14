import 'dart:async';

import 'package:moor/moor.dart';

import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../utils/file.dart';
import '../../utils/load_balancer_utils.dart';
import '../../utils/string_extension.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../converter/message_status_type_converter.dart';
import '../database_event_bus.dart';
import '../extension/message_category.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'message_dao.g.dart';

@UseDao(tables: [Messages])
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

  late Stream<void> searchMessageUpdateEvent = db.tableUpdates(
    TableUpdateQuery.onAllTables([
      db.messages,
      db.users,
      db.conversations,
      db.messagesFts,
    ]),
  );

  late Stream<List<MessageItem>> insertOrReplaceMessageStream = db.eventBus
      .watch<Iterable<String>>(DatabaseEvent.insertOrReplaceMessage)
      .asyncMap(
    (event) {
      final ids = event.toList();
      return _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.messageId.isIn(ids),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(ids.length, 0)).get();
    },
  ).distinct();

  late Stream<NotificationMessage> notificationMessageStream = db.eventBus
      .watch<String>(DatabaseEvent.insert)
      .asyncMap((event) => db.notificationMessage(event).getSingleOrNull())
      .where((event) => event != null)
      .cast<NotificationMessage>();

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
            MessageMentions messageMention)
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
            MessageMentions messageMention)
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
            MessageMentions messageMention)?
        order,
  }) =>
      db.baseMessageItems(
          where,
          (message, sender, participant, snapshot, asset, sticker, hyperlink,
                  sharedUser, conversation, messageMention) =>
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
                  messageMention) ??
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

  Future<int> insert(Message message, String userId) async {
    final result = await db.transaction(() async {
      final futures = <Future>[
        into(db.messages).insertOnConflictUpdate(message),
        _insertMessageFts(message),
        db.conversationDao.updateLastMessageId(
          message.conversationId,
          message.messageId,
          message.createdAt,
        ),
      ];
      return (await Future.wait(futures))[0];
    });
    await takeUnseen(userId, message.conversationId);
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [message.messageId]);
    db.eventBus.send(DatabaseEvent.insert, message.messageId);
    return result;
  }

  Future<void> insertCompanion(MessagesCompanion messagesCompanion) async =>
      into(db.messages).insert(messagesCompanion);

  Future<void> _insertMessageFts(Message message) async {
    String? ftsContent;
    if (message.category.isText || message.category.isPost) {
      ftsContent = message.content;
    } else if (message.category.isData) {
      ftsContent = message.name;
    } else if (message.category.isContact) {
      ftsContent = message.name;
    } else if (message.category == MessageCategory.appCard) {
      final appCard =
          AppCardData.fromJson(await jsonDecodeWithIsolate(message.content!));
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
        'INSERT OR REPLACE INTO messages_fts (message_id, conversation_id, content, created_at, user_id) VALUES (\'$messageId\', \'$conversationId\',\'${content.escapeSqliteSingleQuotationMarks()}\', \'${createdAt.millisecondsSinceEpoch}\', \'$userId\')',
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

  Future<int> updateMediaMessageUrl(String path, String messageId) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(mediaUrl: Value(path.relativePath))),
      );

  Future<int> updateMediaSize(int length, String messageId) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(mediaSize: Value(length))),
      );

  Future<int> updateMediaStatus(MediaStatus status, String messageId) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(mediaStatus: Value(status))),
      );

  Future<int> takeUnseen(String userId, String conversationId) async {
    final messageId = await (db.selectOnly(db.messages)
          ..addColumns([db.messages.messageId])
          ..where(db.messages.conversationId.equals(conversationId) &
              db.messages.status.equals(const MessageStatusTypeConverter()
                  .mapToSql(MessageStatus.read)))
          ..orderBy([
            OrderingTerm(
                expression: db.messages.createdAt, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .map((row) => row.read(db.messages.messageId))
        .getSingleOrNull();

    return db.customUpdate(
      'UPDATE conversations SET last_read_message_id = ?, unseen_message_count = (SELECT count(1) FROM messages m WHERE m.conversation_id = ? AND m.user_id != ? AND m.status IN (\'SENT\', \'DELIVERED\')) WHERE conversation_id = ?',
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
              tbl.status.equalsValue(MessageStatus.failed).not()))
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
    return future.where((element) => element != null).cast<String>().toList();
  }

  Selectable<MessageItem> messagesByConversationId(
    String conversationId,
    int limit, [
    int offset = 0,
  ]) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
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
        final ids =
            list.where((element) => element != null).cast<String>().toList();
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
    return future.where((element) => element != null).cast<String>().toList();
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

  Future<int> updateMessageContent(String messageId, String content) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(content: Value(content))),
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
                  _________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_IMAGE', 'PLAIN_IMAGE']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, offset));

  Selectable<MessageItem> mediaMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId') &
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_IMAGE', 'PLAIN_IMAGE']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, 0));

  Selectable<MessageItem> mediaMessagesAfter(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid > $rowId') &
              message.category.isIn(['SIGNAL_IMAGE', 'PLAIN_IMAGE']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              OrderBy([OrderingTerm.asc(message.createdAt)]));

  Selectable<MessageItem> postMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_POST', 'PLAIN_POST']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, offset));

  Selectable<MessageItem> postMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId') &
              message.category.isIn(['SIGNAL_POST', 'PLAIN_POST']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, 0));

  Selectable<MessageItem> fileMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_DATA', 'PLAIN_DATA']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, offset));

  Selectable<MessageItem> fileMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId') &
              message.category.isIn(['SIGNAL_DATA', 'PLAIN_DATA']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, 0));

  Selectable<MessageItem> beforeMessagesByConversationId(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>('${message.aliasedName}.rowid < $rowId'),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, 0));

  Selectable<MessageItem> afterMessagesByConversationId(
          int rowId, String conversationId, int limit,
          {bool orEqual = false}) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.conversationId.equals(conversationId) &
              CustomExpression<bool>(
                  '${message.aliasedName}.rowid >${orEqual ? '=' : ''} $rowId'),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              OrderBy([OrderingTerm.asc(message.createdAt)]));

  Selectable<MessageItem> messageItemByMessageId(
          String messageId) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________) =>
              message.messageId.equals(messageId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________) =>
              Limit(1, 0));

  Future<void> recallMessage(String messageId) async {
    await (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(const MessagesCompanion(
      category: Value(MessageCategory.messageRecall),
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
    // Maybe use another event
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
  }

  Selectable<SearchMessageDetailItem> fuzzySearchMessage({
    required String query,
    required int limit,
    int offset = 0,
  }) =>
      db.fuzzySearchMessage(
        query.trim().escapeSql().joinStar().replaceQuotationMark(),
        limit,
        offset,
      );

  Selectable<int> fuzzySearchMessageCount(String keyword) =>
      db.fuzzySearchMessageCount(
        keyword.trim().escapeSql().joinStar().replaceQuotationMark(),
      );

  Selectable<SearchMessageDetailItem> fuzzySearchMessageByConversationId({
    required String conversationId,
    required String query,
    required int limit,
    int offset = 0,
  }) =>
      db.fuzzySearchMessageByConversationId(
        conversationId,
        query.trim().escapeSql().joinStar().replaceQuotationMark(),
        limit,
        offset,
      );

  Selectable<int> fuzzySearchMessageCountByConversationId(
          String keyword, String conversationId) =>
      db.fuzzySearchMessageCountByConversationId(
        conversationId,
        keyword.trim().escapeSql().joinStar().replaceQuotationMark(),
      );

  Selectable<int> messageRowId(String messageId) => db.messageRowId(messageId);

  Future<int> deleteFtsByMessageId(String messageId) =>
      (db.delete(db.messagesFts)
            ..where((tbl) => tbl.messageId.equals(messageId)))
          .go();
}
