import 'dart:async';

import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:moor/moor.dart';

import '../../utils/string_extension.dart';
import '../extension/message_category.dart';

part 'messages_dao.g.dart';

@UseDao(tables: [Messages])
class MessagesDao extends DatabaseAccessor<MixinDatabase>
    with _$MessagesDaoMixin {
  MessagesDao(MixinDatabase db) : super(db);

  late Stream<Null> updateEvent = db.tableUpdates(TableUpdateQuery.onAllTables([
    db.messages,
    db.users,
    db.snapshots,
    db.assets,
    db.stickers,
    db.hyperlinks,
    db.messageMentions,
    db.conversations,
  ]));

  late Stream<Null> searchMessageUpdateEvent =
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
    final result = await into(db.messages).insertOnConflictUpdate(message);
    if (message.category.isText) {
      final content = message.content!.fts5ContentFilter();
      insertFts(message.messageId, message.conversationId, content,
          message.createdAt, message.userId);
    }
    await db.conversationsDao
        .updateLastMessageId(message.conversationId, message.messageId);
    await _takeUnseen(userId, message.conversationId);
    db.eventBus.send(DatabaseEvent.insertOrReplaceMessage, [message.messageId]);
    db.eventBus.send(DatabaseEvent.insert, message.messageId);
    return result;
  }

  void insertFts(String messageId, String conversationId, String content,
      DateTime createdAt, String userId) async {
    await db.customInsert(
      'INSERT OR REPLACE INTO messages_fts (message_id, conversation_id, content, created_at, user_id) VALUES (\'$messageId\', \'$conversationId\',\'$content\', \'${createdAt.millisecondsSinceEpoch}\', \'$userId\')',
      updates: {db.messagesFts},
    );
  }

  Future deleteMessage(Message message) => delete(db.messages).delete(message);

  Future<void> deleteMessageByConversationId(String conversationId) =>
      (delete(db.messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Future<SendingMessage?> sendingMessage(String messageId) async {
    final sendingMessage = await db.sendingMessage(messageId).get();
    return sendingMessage.isNotEmpty ? sendingMessage.single : null;
  }

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

  Future<int> _takeUnseen(String userId, String conversationId) {
    return db.customUpdate(
      'UPDATE conversations SET unseen_message_count = (SELECT count(1) FROM messages m WHERE m.conversation_id = ? AND m.user_id != ? AND m.status IN (\'SENT\', \'DELIVERED\')) WHERE conversation_id = ?',
      variables: [
        Variable.withString(conversationId),
        Variable.withString(userId),
        Variable.withString(conversationId)
      ],
      updates: {db.conversations},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> markMessageRead(List<String> messageIds) async =>
      await transaction(() async {
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
      String conversationId, String userId) async {
    return await db.transaction(() async {
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
  }

  Future<QuoteMessageItem?> findMessageItemById(
      String conversationId, String messageId) async {
    return await db
        .findMessageItemById(conversationId, messageId)
        .getSingleOrNull();
  }

  Future<QuoteMessageItem?> findMessageItemByMessageId(
      String? messageId) async {
    if (messageId == null) return null;
    return await db.findMessageItemByMessageId(messageId).getSingleOrNull();
  }

  Future<Message?> findMessageByMessageId(String messageId) async {
    return await db.findMessageByMessageId(messageId).getSingleOrNull();
  }

  void updateMessageContent(String messageId, String encoded) async {
    await db.customUpdate(
      'UPDATE messages SET content = ?, media_status = \'DONE\', status = \'SENDING\' WHERE message_id = ?',
      variables: [Variable.withString(encoded), Variable.withString(messageId)],
      updates: {db.messages},
      updateKind: UpdateKind.update,
    );
  }

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

  Selectable<int> messageIndex(String conversationId, String messageId) =>
      db.messageIndex(conversationId, messageId);

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
      db.fuzzySearchMessage(query, limit, offset);

  Selectable<int> fuzzySearchMessageCount(String keyword) =>
      db.fuzzySearchMessageCount(keyword);

  Selectable<SearchMessageDetailItem> fuzzySearchMessageByConversationId({
    required String conversationId,
    required String query,
    required int limit,
    int offset = 0,
  }) =>
      db.fuzzySearchMessageByConversationId(
          conversationId, query, limit, offset);

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
