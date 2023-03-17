import 'dart:async';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

import '../../constants/constants.dart';
import '../../enum/media_status.dart';
import '../../enum/message_category.dart';
import '../../utils/extension/extension.dart';
import '../database_event_bus.dart';
import '../event.dart';
import '../mixin_database.dart';
import '../util/util.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<MixinDatabase>
    with _$MessageDaoMixin {
  MessageDao(super.db);

  Stream<List<MessageItem>> watchInsertOrReplaceMessageStream(
          String conversationId) =>
      Rx.merge([
        DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
        DataBaseEventBus.instance.updateMessageMentionStream,
        DataBaseEventBus.instance.updatePinMessageStream
      ])
          .map((event) => event
              .where((element) => element.conversationId == conversationId))
          .where((event) => event.isNotEmpty)
          .asyncBufferMap((event) async {
        final miniMessageItems =
            event.reduce((value, element) => [...value, ...element]).toList();
        final messages = <MessageItem>[];
        final chunked = miniMessageItems.chunked(kMarkLimit);
        for (final miniMessageItems in chunked) {
          messages.addAll(await _baseMessageItems(
              (message, _, __, ___, ____, _____, ______, _______, ________,
                      _________, __________, ___________, em) =>
                  message.messageId
                      .isIn(miniMessageItems.map((e) => e.messageId)),
              (_, __, ___, ____, _____, ______, _______, ________, _________,
                      __________, ___________, ____________, em) =>
                  Limit(miniMessageItems.length, 0)).get());
        }
        return messages;
      });

  Selectable<NotificationMessage> notificationMessage(
          List<String> messageIds) =>
      db.notificationMessage(messageIds);

  Selectable<MessageItem> _baseMessageItems(
    Expression<bool> Function(
      Messages message,
      Users sender,
      Users participant,
      Snapshots snapshot,
      Assets asset,
      Chains chain,
      Stickers sticker,
      Hyperlinks hyperlink,
      Users sharedUser,
      Conversations conversation,
      MessageMentions messageMention,
      PinMessages pinMessage,
      ExpiredMessages em,
    )
        where,
    Limit Function(
      Messages message,
      Users sender,
      Users participant,
      Snapshots snapshot,
      Assets asset,
      Chains chain,
      Stickers sticker,
      Hyperlinks hyperlink,
      Users sharedUser,
      Conversations conversation,
      MessageMentions messageMention,
      PinMessages pinMessage,
      ExpiredMessages em,
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
      ExpiredMessages em,
    )?
        order,
  }) =>
      db.baseMessageItems(
          where,
          (message, sender, participant, snapshot, asset, _, sticker, hyperlink,
                  sharedUser, conversation, messageMention, pinMessage, em) =>
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
                  pinMessage,
                  em) ??
              OrderBy([
                OrderingTerm.desc(message.createdAt),
                OrderingTerm.desc(message.rowId)
              ]),
          limit);

  Future<T> _sendInsertOrReplaceEventWithFuture<T>(
    List<String> messageIds,
    Future<T> future,
  ) async {
    final result = await future;
    final miniMessage = await db.miniMessageByIds(messageIds).get();
    DataBaseEventBus.instance.insertOrReplaceMessages(miniMessage);
    return result;
  }

  final Map<String, void Function()> _conversationUnseenTaskRunner = {};

  void _updateConversationUnseenCount(
    Message message,
    String currentUserId,
  ) {
    Future<void> _update(Message message) async {
      await db.updateUnseenMessageCountAndLastMessageId(
        message.conversationId,
        currentUserId,
        message.messageId,
        message.createdAt,
      );

      DataBaseEventBus.instance.updateConversation(message.conversationId);
    }

    if (_conversationUnseenTaskRunner[message.conversationId] != null) {
      _conversationUnseenTaskRunner[message.conversationId] =
          () => _update(message);
      return;
    } else {
      _conversationUnseenTaskRunner[message.conversationId] =
          () => _update(message);
      Future.delayed(kDefaultThrottleDuration ~/ 5).then((value) {
        final runner =
            _conversationUnseenTaskRunner.remove(message.conversationId);
        runner?.call();
      });
    }
  }

  Future<int> insert(
    Message message,
    String currentUserId, {
    bool? silent = false,
    int expireIn = 0,
  }) async {
    final futures = <Future>[
      into(db.messages).insertOnConflictUpdate(message),
      if (expireIn > 0)
        db.expiredMessageDao
            .insert(messageId: message.messageId, expireIn: expireIn)
    ];
    final result = (await Future.wait(futures)).first as int;

    _updateConversationUnseenCount(message, currentUserId);

    DataBaseEventBus.instance.insertOrReplaceMessages([
      MiniMessageItem(
        messageId: message.messageId,
        conversationId: message.conversationId,
      )
    ]);
    if (!(silent ?? false)) {
      DataBaseEventBus.instance.notificationMessage(MiniNotificationMessage(
        messageId: message.messageId,
        conversationId: message.conversationId,
        senderId: message.userId,
        type: message.category,
        createdAt: message.createdAt,
      ));
    }

    return result;
  }

  Future<void> deleteMessage(
    String conversationId,
    String messageId,
  ) async {
    Future<void> updateConversationLastMessageId() async {
      final messages = db.messages;
      final lastTwo = await (selectOnly(messages)
            ..addColumns([messages.messageId, messages.createdAt])
            ..where(messages.conversationId.equals(conversationId))
            ..limit(2)
            ..orderBy([OrderingTerm.desc(messages.createdAt)]))
          .map((row) => Tuple2(
              row.read(messages.messageId),
              messages.createdAt.converter
                  .fromSql(row.read(messages.createdAt))))
          .get();

      if (lastTwo.isEmpty) return;
      if (lastTwo.firstOrNull?.item1 != messageId) return;

      final newLast = lastTwo.lastOrNull;

      await (update(db.conversations)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .write(ConversationsCompanion(
        lastMessageId: Value(newLast?.item1),
        lastMessageCreatedAt: Value(newLast?.item2),
      ))
          .then((value) {
        if (value > 0) {
          DataBaseEventBus.instance.updateConversation(conversationId);
        }

        return value;
      });
    }

    await updateConversationLastMessageId();

    await db.transaction(() async {
      await Future.wait([
        (delete(db.messages)..where((tbl) => tbl.messageId.equals(messageId)))
            .go(),
        (delete(db.transcriptMessages)
              ..where((tbl) => tbl.transcriptId.equals(messageId)))
            .go(),
        _recallPinMessage(conversationId, messageId),
        db.pinMessageDao.deleteByIds([messageId]),
        db.expiredMessageDao.deleteByMessageId(messageId),
      ]);
    });
    DataBaseEventBus.instance.deleteMessage(messageId);
    DataBaseEventBus.instance.updatePinMessage([
      MiniMessageItem(conversationId: conversationId, messageId: messageId)
    ]);

    DataBaseEventBus.instance.updateTranscriptMessage(
        [MiniTranscriptMessage(transcriptId: messageId)]);
  }

  Future<void> deleteMessageByConversationId(String conversationId) =>
      (delete(db.messages)
            ..where((tbl) => tbl.conversationId.equals(conversationId)))
          .go();

  Future<SendingMessage?> sendingMessage(String messageId) async =>
      db.sendingMessage(messageId).getSingleOrNull();

  Future<int> updateMessageStatusById(
      String messageId, MessageStatus status) async {
    final already = await db.hasData(
        db.messages,
        [],
        db.messages.messageId.equals(messageId) &
            db.messages.status.equalsValue(status));
    if (already) return -1;
    return _sendInsertOrReplaceEventWithFuture(
      [messageId],
      (db.update(db.messages)..where((tbl) => tbl.messageId.equals(messageId)))
          .write(MessagesCompanion(status: Value(status))),
    );
  }

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
    if (!await hasMediaStatus(messageId, status, true)) return;

    final result = await db.transaction<List>(() => Future.wait([
          (db.update(db.messages)
                ..where((tbl) => tbl.messageId.equals(messageId)))
              .write(MessagesCompanion(mediaStatus: Value(status))),
          (db.update(db.transcriptMessages)
                ..where((tbl) => tbl.messageId.equals(messageId)))
              .write(TranscriptMessagesCompanion(mediaStatus: Value(status))),
        ]));
    if (result.cast<int>().any((element) => element > -1)) {
      final conversationId = await findConversationIdByMessageId(messageId);
      if (conversationId == null) return;
      DataBaseEventBus.instance.insertOrReplaceMessages([
        MiniMessageItem(
          messageId: messageId,
          conversationId: conversationId,
        )
      ]);
    }
  }

  Future<bool> messageHasMediaStatus(String messageId, MediaStatus mediaStatus,
      [bool not = false]) async {
    final equalsId = db.messages.messageId.equals(messageId);
    final equalsStatus = db.messages.mediaStatus.equalsValue(mediaStatus);
    final predicate =
        not ? equalsId & equalsStatus.not() : equalsId & equalsStatus;
    return db.hasData(db.messages, [], predicate);
  }

  Future<bool> transcriptMessageHasMediaStatus(
      String messageId, MediaStatus mediaStatus,
      [bool not = false]) async {
    final equalsId = db.transcriptMessages.messageId.equals(messageId);
    final equalsStatus =
        db.transcriptMessages.mediaStatus.equalsValue(mediaStatus);
    final predicate =
        not ? equalsId & equalsStatus.not() : equalsId & equalsStatus;
    return db.hasData(db.transcriptMessages, [], predicate);
  }

  Future<bool> hasMediaStatus(String messageId, MediaStatus mediaStatus,
      [bool not = false]) async {
    final result = await Future.wait([
      messageHasMediaStatus(messageId, mediaStatus, not),
      transcriptMessageHasMediaStatus(messageId, mediaStatus, not)
    ]);
    return result.any((element) => element);
  }

  Future<void> syncMessageMedia(String messageId) async {
    var content = db.messages.content;
    var mediaUrl = db.messages.mediaUrl;
    var mediaSize = db.messages.mediaSize;
    var mediaStatus = db.messages.mediaStatus;

    var result = await (db.selectOnly(db.messages)
          ..addColumns([content, mediaUrl, mediaSize, mediaStatus])
          ..where(db.messages.messageId.equals(messageId) &
              db.messages.mediaStatus.equalsValue(MediaStatus.done))
          ..limit(1))
        .getSingleOrNull();
    if (result == null) {
      content = db.transcriptMessages.content;
      mediaUrl = db.transcriptMessages.mediaUrl;
      mediaSize = db.transcriptMessages.mediaSize;
      mediaStatus = db.transcriptMessages.mediaStatus;

      result = await (db.selectOnly(db.transcriptMessages)
            ..addColumns([content, mediaUrl, mediaSize, mediaStatus])
            ..where(db.transcriptMessages.messageId.equals(messageId) &
                db.transcriptMessages.mediaStatus.equalsValue(MediaStatus.done))
            ..limit(1))
          .getSingleOrNull();
    }

    if (result == null) return;

    await updateMedia(
      path: result.read(mediaUrl)!,
      messageId: messageId,
      mediaSize: result.read(mediaSize)!,
      mediaStatus: mediaStatus.converter.fromSql(result.read(mediaStatus))!,
      content: result.read(content),
    );
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

    final countColumn = db.messages.messageId.count();
    final count = await (selectOnly(db.messages)
          ..addColumns([countColumn])
          ..where(db.messages.conversationId.equals(conversationId) &
              db.messages.userId.equals(userId).not() &
              db.messages.status.isIn([
                MessageStatus.sent,
                MessageStatus.delivered
              ].map((e) => db.messages.status.converter.toSql(e)!))))
        .map((row) => row.read(countColumn))
        .getSingleOrNull();

    final already = await db.hasData(
        db.conversations,
        [],
        db.conversations.conversationId.equals(conversationId) &
            db.conversations.lastMessageId.equalsNullable(messageId) &
            db.conversations.unseenMessageCount.equalsNullable(count));

    // For reduce update event
    if (already) return -1;

    return (update(db.conversations)
          ..where((tbl) => tbl.conversationId.equals(conversationId)))
        .write(ConversationsCompanion(
      lastReadMessageId: Value(messageId),
      unseenMessageCount: Value(count),
    ))
        .then((value) {
      if (value > 0) {
        DataBaseEventBus.instance.updateConversation(conversationId);
      }
      return value;
    });
  }

  Future<int> markMessageRead(
    Iterable<MiniMessageItem> miniMessageItems, {
    bool updateExpired = true,
  }) async {
    final messageIds = miniMessageItems.map((e) => e.messageId);
    final result = await (db.update(db.messages)
          ..where((tbl) =>
              tbl.messageId.isIn(messageIds) &
              tbl.status.equalsValue(MessageStatus.failed).not() &
              tbl.status.equalsValue(MessageStatus.unknown).not()))
        .write(const MessagesCompanion(status: Value(MessageStatus.read)));

    DataBaseEventBus.instance.insertOrReplaceMessages(miniMessageItems);
    if (updateExpired) {
      await db.expiredMessageDao.onMessageRead(messageIds);
    }
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
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, offset));

  Selectable<int> messageCountByConversationId(String conversationId) {
    final countExp = countAll();
    return (db.selectOnly(db.messages)
          ..addColumns([countExp])
          ..where(db.messages.conversationId.equals(conversationId)))
        .map(
      (row) => row.read(countExp)!,
    );
  }

  Future<List<String>> getUnreadMessageIds(
      String conversationId, String userId, int limit) async {
    final list = await (db.selectOnly(db.messages)
          ..addColumns([db.messages.messageId])
          ..where(db.messages.conversationId.equals(conversationId) &
              db.messages.userId.equals(userId).not() &
              db.messages.status.isIn(['SENT', 'DELIVERED']))
          ..limit(limit))
        .map((row) => row.read(db.messages.messageId))
        .get();
    final ids = list.whereNotNull().toList();
    if (ids.isNotEmpty) {
      await markMessageRead(ids.map((e) =>
          MiniMessageItem(conversationId: conversationId, messageId: e)));
    }
    await takeUnseen(userId, conversationId);
    return ids;
  }

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

  Selectable<MiniMessageItem> miniMessageByIds(List<String> messageIds) =>
      db.miniMessageByIds(messageIds);

  Future<Message?> findMessageByMessageId(String messageId) =>
      (db.select(db.messages)
            ..where((tbl) => tbl.messageId.equals(messageId))
            ..limit(1))
          .getSingleOrNull();

  Future<String?> findConversationIdByMessageId(String messageId) =>
      (db.selectOnly(db.messages)
            ..addColumns([db.messages.conversationId])
            ..where(db.messages.messageId.equals(messageId)))
          .map((row) => row.read(db.messages.conversationId))
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
          .map((row) => row.read(db.messages.messageId.count())!)
          .getSingle();

  Future<void> updateQuoteContentByQuoteId(
      String conversationId, String quoteMessageId, String content) async {
    final messageIds = (await (db.selectOnly(db.messages, distinct: true)
              ..addColumns([db.messages.messageId])
              ..where(db.messages.conversationId.equals(conversationId) &
                  db.messages.quoteMessageId.equals(quoteMessageId)))
            .map((row) => row.read(db.messages.messageId))
            .get())
        .whereNotNull()
        .toList();

    if (messageIds.isEmpty) return;

    await _sendInsertOrReplaceEventWithFuture(
        messageIds,
        (db.update(db.messages)
              ..where((tbl) =>
                  tbl.conversationId.equals(conversationId) &
                  tbl.quoteMessageId.equals(quoteMessageId)))
            .write(MessagesCompanion(quoteContent: Value(content))));
  }

  Future<int> updateAttachmentMessageContentAndStatus(
          String messageId, String content, String? key, String? digest) =>
      _sendInsertOrReplaceEventWithFuture(
        [messageId],
        (db.update(db.messages)
              ..where((tbl) => tbl.messageId.equals(messageId)))
            .write(MessagesCompanion(
          mediaStatus: const Value(MediaStatus.done),
          status: const Value(MessageStatus.sending),
          mediaKey: key != null ? Value(key) : const Value.absent(),
          mediaDigest: digest != null ? Value(digest) : const Value.absent(),
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
      String messageId, String? content, MessageStatus status) async {
    final already = await db.hasData(
        db.messages,
        [],
        db.messages.messageId.equals(messageId) &
            db.messages.status.equalsValue(status) &
            db.messages.category.equals(MessageCategory.messageRecall).not() &
            (content != null
                ? db.messages.content.equals(content)
                : ignoreWhere));
    if (already) return -1;

    return _sendInsertOrReplaceEventWithFuture(
      [messageId],
      (db.update(db.messages)
            ..where((tbl) =>
                tbl.messageId.equals(messageId) &
                tbl.category.equals(MessageCategory.messageRecall).not()))
          .write(MessagesCompanion(
        content: content != null ? Value(content) : const Value.absent(),
        status: Value(status),
      )),
    );
  }

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

  static const _mediaMessageTypes = [
    MessageCategory.signalImage,
    MessageCategory.plainImage,
    MessageCategory.encryptedImage,
    MessageCategory.signalVideo,
    MessageCategory.plainVideo,
    MessageCategory.encryptedVideo,
  ];

  Selectable<MessageItem> mediaMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(_mediaMessageTypes),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, offset));

  Selectable<MessageItem> mediaMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, ____________) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(_mediaMessageTypes) &
              message.rowId.isSmallerThanValue(rowId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, _____________) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________) =>
              OrderBy([OrderingTerm.desc(message.createdAt)]));

  Selectable<MessageItem> mediaMessagesAfter(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(_mediaMessageTypes) &
              message.rowId.isBiggerThanValue(rowId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, _____________) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________) =>
              OrderBy([OrderingTerm.asc(message.createdAt)]));

  Selectable<MessageItem> postMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_POST', 'PLAIN_POST']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, offset));

  Selectable<MessageItem> postMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_POST', 'PLAIN_POST']) &
              message.rowId.isSmallerThanValue(rowId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, 0));

  Selectable<MessageItem> fileMessages(
          String conversationId, int limit, int offset) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_DATA', 'PLAIN_DATA']),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, offset));

  Selectable<MessageItem> fileMessagesBefore(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.category.isIn(['SIGNAL_DATA', 'PLAIN_DATA']) &
              message.rowId.isSmallerThanValue(rowId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, 0));

  Selectable<MessageItem> beforeMessagesByConversationId(
          int rowId, String conversationId, int limit) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              message.rowId.isSmallerThanValue(rowId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, 0));

  Selectable<MessageItem> afterMessagesByConversationId(
          int rowId, String conversationId, int limit,
          {bool orEqual = false}) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.conversationId.equals(conversationId) &
              (orEqual
                  ? message.rowId.isBiggerOrEqualValue(rowId)
                  : message.rowId.isBiggerThanValue(rowId)),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(limit, 0),
          order: (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, em) =>
              OrderBy([OrderingTerm.asc(message.createdAt)]));

  Selectable<MessageItem> messageItemByMessageId(
          String messageId) =>
      _baseMessageItems(
          (message, _, __, ___, ____, _____, ______, _______, ________,
                  _________, __________, ___________, em) =>
              message.messageId.equals(messageId),
          (_, __, ___, ____, _____, ______, _______, ________, _________,
                  __________, ___________, ____________, em) =>
              Limit(1, 0));

  Selectable<MessageItem> messageItemByMessageIds(List<String> messageIds) =>
      _baseMessageItems(
        (message, _, __, ___, ____, _____, ______, _______, ________, _________,
                __________, ___________, em) =>
            message.messageId.isIn(messageIds),
        (_, __, ___, ____, _____, ______, _______, ________, _________,
                __________, ___________, ____________, em) =>
            maxLimit,
        order: (message, _, __, ___, ____, _____, ______, _______, ________,
                _________, __________, em) =>
            OrderBy([OrderingTerm.asc(message.createdAt)]),
      );

  Future<MessageItem?> findNextAudioMessageItem({
    required String conversationId,
    required String messageId,
    required DateTime createdAt,
  }) async {
    final rowId = await messageRowId(messageId).getSingleOrNull() ?? -1;
    return _baseMessageItems(
      (message, _, __, ___, ____, _____, ______, _______, ________,
              conversation, _________, ___________, em) =>
          conversation.conversationId.equals(conversationId) &
          message.category.isIn([
            MessageCategory.signalAudio,
            MessageCategory.plainAudio,
            MessageCategory.encryptedAudio
          ]) &
          message.createdAt.isBiggerOrEqualValue(
              message.createdAt.converter.toSql(createdAt)!) &
          message.rowId.isBiggerThanValue(rowId),
      (_, __, ___, ____, _____, ______, _______, ________, _________,
              __________, ___________, ____________, em) =>
          Limit(1, 0),
      order: (message, _, __, ___, ____, _____, ______, _______, ________,
              _________, __________, em) =>
          OrderBy([OrderingTerm.asc(message.createdAt)]),
    ).getSingleOrNull();
  }

  Future<void> _recallPinMessage(
      String conversationId, String messageId) async {
    final messages = db.messages;

    while (true) {
      final messageIds = (await (db.selectOnly(messages)
                ..addColumns([messages.messageId])
                ..where(messages.conversationId.equals(conversationId) &
                    messages.category.equals(MessageCategory.messagePin) &
                    messages.quoteMessageId.equals(messageId))
                ..limit(100))
              .map((row) => row.read(messages.messageId))
              .get())
          .whereNotNull();

      if (messageIds.isEmpty) return;

      await (db.update(messages)
            ..where(
              (tbl) => tbl.messageId.isIn(messageIds),
            ))
          .write(const MessagesCompanion(
        content: Value(null),
      ));

      DataBaseEventBus.instance
          .insertOrReplaceMessages(messageIds.map((e) => MiniMessageItem(
                messageId: e,
                conversationId: conversationId,
              )));
    }
  }

  Future<void> recallMessage(String conversationId, String messageId) async {
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

    await _recallPinMessage(conversationId, messageId);

    await db.pinMessageDao.deleteByIds([messageId]);
    final miniMessageItem = MiniMessageItem(
      messageId: messageId,
      conversationId: conversationId,
    );

    DataBaseEventBus.instance.insertOrReplaceMessages([miniMessageItem]);
    DataBaseEventBus.instance.notificationMessage(MiniNotificationMessage(
      messageId: messageId,
      conversationId: conversationId,
      type: MessageCategory.messageRecall,
    ));
  }

  Selectable<int?> messageRowId(String messageId) => (selectOnly(db.messages)
        ..addColumns([db.messages.rowId])
        ..where(db.messages.messageId.equals(messageId))
        ..limit(1)
        ..orderBy([OrderingTerm.desc(db.messages.createdAt)]))
      .map((row) => row.read(db.messages.rowId));

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

  Future<void> updateGiphyMessage(String messageId, String mediaUrl,
          int mediaSize, String? thumbImage) =>
      (db.update(db.messages)..where((tbl) => tbl.messageId.equals(messageId)))
          .write(MessagesCompanion(
        mediaUrl: Value(mediaUrl),
        mediaSize: Value(mediaSize),
        thumbImage: Value(thumbImage),
      ));

  Future<void> updateCategoryById(String messageId, String category) =>
      (db.update(db.messages)..where((tbl) => tbl.messageId.equals(messageId)))
          .write(MessagesCompanion(
        category: Value(category),
      ));

  Future<List<Tuple2<int, Message>>> getMessages(int? rowid, int limit) async {
    final messages = await customSelect(
        'SELECT rowid, * FROM messages WHERE ${rowid == null ? '1' : 'rowid < $rowid'} '
        "AND status != 'FAILED' AND status != 'UNKNOWN' "
        'ORDER BY rowid DESC LIMIT $limit',
        readsFrom: {db.messages}).map(
      (row) async {
        final message = await db.messages.mapFromRow(row);
        final rowId = row.read<int>('rowid');
        return Tuple2(rowId, message);
      },
    ).get();
    return Future.wait(messages);
  }
}
