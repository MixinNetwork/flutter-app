import 'dart:async';

import 'package:moor/moor.dart';

import '../../enum/media_status.dart';
import '../../enum/message_status.dart';
import '../../utils/string_extension.dart';
import '../converter/message_status_type_converter.dart';
import '../database_event_bus.dart';
import '../extension/message_category.dart';
import '../mixin_database.dart';

part 'messages_dao.g.dart';

@UseDao(tables: [Messages])
class MessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(MixinDatabase db) : super(db);

  late Stream<void> updateEvent = db.tableUpdates(TableUpdateQuery.onAllTables([
    db.messages,
    db.users,
    db.snapshots,
    db.assets,
    db.stickers,
    db.hyperlinks,
    db.messageMentions,
    db.conversations,
  ]));

  late Stream<void> searchMessageUpdateEvent =
      db.tableUpdates(TableUpdateQuery.onAllTables([
    db.messages,
    db.users,
    db.conversations,
    db.messagesFts,
  ]));

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

  Future<int> insert(Message message, String userId) async {
    final result = await db.transaction(() async {
      final futures = <Future>[
        into(db.messages).insertOnConflictUpdate(message)
      ];
      if (message.category.isText) {
        final content = message.content!.fts5ContentFilter();
        futures.add(insertFts(
          message.messageId,
          message.conversationId,
          content,
          message.createdAt,
          message.userId,
        ));
      }
      futures.add(db.conversationsDao.updateLastMessageId(
        message.conversationId,
        message.messageId,
        message.createdAt,
      ));
      return (await Future.wait(futures))[0];
    });
    await _takeUnseen(userId, message.conversationId);
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [message.messageId]);
    db.eventBus.send(DatabaseEvent.insert, message.messageId);
    return result;
  }

  Future<void> insertCompanion(MessagesCompanion messagesCompanion) async =>
      into(db.messages).insert(messagesCompanion);

  Future<int> insertFts(String messageId, String conversationId, String content,
          DateTime createdAt, String userId) =>
      db.customInsert(
        'INSERT OR REPLACE INTO messages_fts (message_id, conversation_id, content, created_at, user_id) VALUES (\'$messageId\', \'$conversationId\',\'${content.escapeSqliteSingleQuotationMarks()}\', \'${createdAt.millisecondsSinceEpoch}\', \'$userId\')',
        updates: {db.messagesFts},
      );

  Future deleteMessage(Message message) => delete(db.messages).delete(message);

  Future<void> deleteMessageByConversationId(String conversationId) =>
      (delete(db.messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Future<SendingMessage?> sendingMessage(String messageId) async =>
      db.sendingMessage(messageId).getSingleOrNull();

  Future<int> updateMessageStatusById(
      String messageId, MessageStatus status) async {
    final result = await (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(MessagesCompanion(status: Value(status)));
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
    return result;
  }

  Future<MessageStatus?> findMessageStatusById(String messageId) =>
      db.findMessageStatusById(messageId).getSingleOrNull();

  Future<int> updateMediaMessageUrl(String path, String messageId) async {
    final result = await (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(MessagesCompanion(mediaUrl: Value(path)));
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
    return result;
  }

  Future<int> updateMediaSize(int length, String messageId) async {
    final result = await (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(MessagesCompanion(mediaSize: Value(length)));
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
    return result;
  }

  Future<int> updateMediaStatus(MediaStatus status, String messageId) async {
    final result = await (db.update(db.messages)
          ..where((tbl) => tbl.messageId.equals(messageId)))
        .write(MessagesCompanion(mediaStatus: Value(status)));
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [messageId]);
    return result;
  }

  Future<int> _takeUnseen(String userId, String conversationId) async {
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

  Future<void> markMessageRead(List<String> messageIds) =>
      transaction(() async {
        for (final id in messageIds) {
          await (update(db.messages)..where((e) => e.messageId.equals(id)))
              .write(const MessagesCompanion(
                  status: Value<MessageStatus>(MessageStatus.read)));
        }
      });

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
        .map((row) => row.read(countExp));
  }

  Future<List<String>> getUnreadMessageIds(
          String conversationId, String userId) =>
      db.transaction(() async {
        final list = await db
            .customSelect(
                'SELECT message_id FROM messages WHERE conversation_id = ? AND user_id != ? AND status IN (\'SENT\', \'DELIVERED\') ORDER BY created_at ASC',
                readsFrom: {
                  db.messages
                },
                variables: [
                  Variable.withString(conversationId),
                  Variable.withString(userId)
                ])
            .map((row) => row.read<String>('message_id'))
            .get();
        await db.customUpdate(
          'UPDATE messages SET status = \'READ\' WHERE conversation_id = ? AND user_id != ? AND status IN (\'SENT\', \'DELIVERED\')',
          variables: [
            Variable.withString(conversationId),
            Variable.withString(userId)
          ],
          updates: {db.messages},
          updateKind: UpdateKind.update,
        );
        await _takeUnseen(userId, conversationId);
        return list;
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
              'SELECT id FROM messages WHERE conversation_id = ? AND user_id = ? AND status = \'FAILED\' ORDER BY created_at DESC LIMIT 1000',
              variables: [
                Variable.withString(conversationId),
                Variable.withString(userId)
              ])
          .map((row) => row.read<String>('message_id'))
          .get();

  Future<int> updateMessageContent(String messageId, String encoded) =>
      db.customUpdate(
        'UPDATE messages SET content = ?, media_status = \'DONE\', status = \'SENDING\' WHERE message_id = ?',
        variables: [
          Variable.withString(encoded),
          Variable.withString(messageId)
        ],
        updates: {db.messages},
        updateKind: UpdateKind.update,
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
      db.fuzzySearchMessageCount(keyword);

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
      db.fuzzySearchMessageCountByConversationId(conversationId, keyword);

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
}
