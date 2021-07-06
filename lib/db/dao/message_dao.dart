import 'dart:async';

import 'package:moor/moor.dart';

import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../enum/message_status.dart';
import '../../utils/load_balancer_utils.dart';
import '../../utils/string_extension.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../converter/message_status_type_converter.dart';
import '../database_event_bus.dart';
import '../extension/message_category.dart';
import '../mixin_database.dart';

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
        (event) => db.messagesByMessageIds(event.toList()).get(),
      )
      .distinct();

  late Stream<NotificationMessage> notificationMessageStream = db.eventBus
      .watch<String>(DatabaseEvent.insert)
      .asyncMap((event) => db.notificationMessage(event).getSingleOrNull())
      .where((event) => event != null)
      .cast<NotificationMessage>();

  late Stream<String> deleteMessageIdStream =
      db.eventBus.watch<String>(DatabaseEvent.delete);

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
            .write(MessagesCompanion(mediaUrl: Value(path))),
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
              tbl.status.equals('FAILED').not()))
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
      db.messagesByConversationId(
        conversationId,
        offset,
        limit,
      );

  Selectable<MessageItem> beforeMessagesByConversationId(
          int rowId, String conversationId, int limit) =>
      db.beforeMessagesByConversationId(rowId, conversationId, limit);

  Selectable<MessageItem> afterMessagesByConversationId(
          int rowId, String conversationId, int limit) =>
      db.afterMessagesByConversationId(rowId, conversationId, limit);

  Selectable<MessageItem> messageItemByMessageId(String messageId) =>
      db.messageItemByMessageId(messageId);

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
      db.findMessageItemById(conversationId, messageId).getSingleOrNull();

  Future<QuoteMessageItem?> findMessageItemByMessageId(
      String? messageId) async {
    if (messageId == null) return null;
    return db.findMessageItemByMessageId(messageId).getSingleOrNull();
  }

  Future<Message?> findMessageByMessageId(String messageId) =>
      db.findMessageByMessageId(messageId).getSingleOrNull();

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
      db
          .customSelect(
              'SELECT message_id FROM messages WHERE conversation_id = ? AND user_id = ? AND status = \'FAILED\' ORDER BY created_at DESC LIMIT 1000',
              variables: [
                Variable.withString(conversationId),
                Variable.withString(userId)
              ])
          .map((row) => row.read<String>('message_id'))
          .get();

  Future<int> countMessageByQuoteId(String conversationId, String messageId) =>
      (db.customSelect(
        'SELECT count(message_id) FROM messages WHERE conversation_id = :conversationId AND quote_message_id = :messageId AND quote_content IS NULL',
        variables: [
          Variable.withString(conversationId),
          Variable.withString(messageId),
        ],
      )).map((row) => row.read<int>('count(message_id)')).getSingle();

  Future<int> updateQuoteContentByQuoteId(
      String conversationId, String quoteMessageId, String content) async {
    final messageIds = await _findMessageIdByQuoteMessageId(quoteMessageId);
    return _sendInsertOrReplaceEventWithFuture(
        messageIds,
        db.updateQuoteContentByQuoteId(
            content, conversationId, quoteMessageId));
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
          String messageId, String encoded) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.customUpdate(
          'UPDATE messages SET content = ?, media_status = \'DONE\', status = \'SENDING\' WHERE message_id = ?',
          variables: [
            Variable.withString(encoded),
            Variable.withString(messageId)
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        ),
      );

  Future<int> updateMessageContent(String messageId, String encoded) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.customUpdate(
          'UPDATE messages SET content = ? WHERE message_id = ?',
          variables: [
            Variable.withString(encoded),
            Variable.withString(messageId)
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        ),
      );

  Future<int> updateMessageContentAndStatus(
          String messageId, String content, MessageStatus status) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.customUpdate(
          'UPDATE messages SET content = :content, status = :status WHERE message_id = :id AND category != \'MESSAGE_RECALL\'',
          variables: [
            Variable.withString(content),
            Variable.withString(
                const MessageStatusTypeConverter().mapToSql(status)!),
            Variable.withString(messageId),
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        ),
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
        db.customUpdate(
          'UPDATE messages SET sticker_id = :stickerId, status = :status WHERE message_id = :messageId AND category != \'MESSAGE_RECALL\'',
          variables: [
            Variable.withString(stickerId),
            Variable.withString(
                const MessageStatusTypeConverter().mapToSql(status)!),
            Variable.withString(messageId),
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        ),
      );

  Future<int> updateContactMessage(
          String messageId, MessageStatus status, String sharedUserId) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.customUpdate(
          'UPDATE messages SET shared_user_id = :sharedUserId, status = :status WHERE message_id = :messageId AND category != \'MESSAGE_RECALL\'',
          variables: [
            Variable.withString(sharedUserId),
            Variable.withString(
                const MessageStatusTypeConverter().mapToSql(status)!),
            Variable.withString(messageId),
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        ),
      );

  Future<int> updateLiveMessage(String messageId, int width, int height,
          String url, String thumbUrl, MessageStatus status) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        db.customUpdate(
          '''
    UPDATE messages SET media_width = :width, media_height = :height, media_url=:url, thumb_url = :thumbUrl, status = :status 
    WHERE message_id = :messageId AND category != 'SIGNAL_LIVE'
    ''',
          variables: [
            Variable.withInt(width),
            Variable.withInt(height),
            Variable.withString(url),
            Variable.withString(thumbUrl),
            Variable.withString(
                const MessageStatusTypeConverter().mapToSql(status)!),
            Variable.withString(messageId),
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        ),
      );

  Selectable<int> mediaMessageRowIdByConversationId(
    String conversationId,
    String messageId,
  ) =>
      db.mediaMessageRowIdByConversationId(conversationId, messageId);

  Selectable<int> mediaMessagesCount(String conversationId) =>
      db.mediaMessagesCount(conversationId);

  Selectable<MessageItem> mediaMessages(
          String conversationId, int limit, int offset) =>
      db.mediaMessages(conversationId, offset, limit);

  Future<void> recallMessage(String messageId) async {
    await db.recallMessage(messageId);
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

  Selectable<MessageItem> mediaMessagesBefore(
          int rowid, String conversationId, int limit) =>
      db.mediaMessagesBefore(
        rowid,
        conversationId,
        limit,
      );

  Selectable<MessageItem> mediaMessagesAfter(
          int rowid, String conversationId, int limit) =>
      db.mediaMessagesAfter(
        rowid,
        conversationId,
        limit,
      );

  Selectable<MessageItem> postMessages(
          String conversationId, int limit, int offset) =>
      db.postMessages(conversationId, offset, limit);

  Selectable<MessageItem> postMessagesBefore(
          int rowid, String conversationId, int limit) =>
      db.postMessagesBefore(
        rowid,
        conversationId,
        limit,
      );

  Selectable<MessageItem> fileMessages(
          String conversationId, int limit, int offset) =>
      db.fileMessages(conversationId, offset, limit);

  Selectable<MessageItem> fileMessagesBefore(
          int rowid, String conversationId, int limit) =>
      db.fileMessagesBefore(
        rowid,
        conversationId,
        limit,
      );

  Selectable<int> messageRowId(String messageId) => db.messageRowId(messageId);

  Future<int> deleteFtsByMessageId(String messageId) =>
      db.deleteFtsByMessageId(messageId);
}
