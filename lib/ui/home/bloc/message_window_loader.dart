part of 'message_bloc.dart';

typedef RecentMessagesQuery =
    Future<List<MessageItem>> Function(String conversationId, int limit);
typedef MessageOrderInfoQuery =
    Future<MessageOrderInfo?> Function(String messageId);
typedef AroundMessagesQuery =
    Future<List<MessageItem>> Function(
      MessageOrderInfo anchor,
      String conversationId,
      int limit,
    );
typedef MessageByIdQuery = Future<MessageItem?> Function(String messageId);

class MessageWindowLoader {
  const MessageWindowLoader({
    required this.recentMessages,
    required this.messageOrderInfo,
    required this.beforeMessages,
    required this.afterMessages,
    required this.messageById,
  });

  factory MessageWindowLoader.fromDao(MessageDao messageDao) =>
      MessageWindowLoader(
        recentMessages: (conversationId, limit) =>
            messageDao.messagesByConversationId(conversationId, limit).get(),
        messageOrderInfo: messageDao.messageOrderInfo,
        beforeMessages: (anchor, conversationId, limit) => messageDao
            .beforeMessagesByConversationId(anchor, conversationId, limit)
            .get(),
        afterMessages: (anchor, conversationId, limit) => messageDao
            .afterMessagesByConversationId(anchor, conversationId, limit)
            .get(),
        messageById: (messageId) =>
            messageDao.messageItemByMessageId(messageId).getSingleOrNull(),
      );

  final RecentMessagesQuery recentMessages;
  final MessageOrderInfoQuery messageOrderInfo;
  final AroundMessagesQuery beforeMessages;
  final AroundMessagesQuery afterMessages;
  final MessageByIdQuery messageById;

  Future<MessageState> load(
    String conversationId,
    int limit, {
    String? centerMessageId,
    void Function(String message)? trace,
  }) async {
    Future<MessageState> recent() async {
      final list = await recentMessages(conversationId, limit);

      trace?.call('query recent count=${list.length} limit=$limit');
      return MessageState(
        top: list.reversed.toList(),
        isLatest: true,
        isOldest: list.length < limit,
      );
    }

    if (centerMessageId == null) return recent();

    final info = await messageOrderInfo(centerMessageId);
    if (info == null) {
      trace?.call(
        'query center missing-order target=${shortMessageId(centerMessageId)}',
      );
      return recent();
    }

    final halfLimit = limit ~/ 2;
    final bottomFuture = afterMessages(info, conversationId, halfLimit);
    final topFuture = beforeMessages(info, conversationId, halfLimit);
    final centerFuture = messageById(centerMessageId);

    final bottomList = await bottomFuture;
    var topList = (await topFuture).reversed.toList();
    var center = await centerFuture;

    final isLatest = bottomList.length < halfLimit;
    final isOldest = topList.length < halfLimit;

    if (bottomList.isEmpty && center != null) {
      topList = [...topList, center];
      center = null;
    }

    trace?.call(
      'query centered target=${shortMessageId(centerMessageId)} '
      'top=${topList.length} center=${center != null} '
      'bottom=${bottomList.length} isLatest=$isLatest isOldest=$isOldest',
    );
    return MessageState(
      top: topList,
      center: center,
      bottom: bottomList,
      isLatest: isLatest,
      isOldest: isOldest,
    );
  }
}
