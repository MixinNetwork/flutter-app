part of 'message_controller.dart';

typedef RecentMessagesQuery =
    Future<List<MessageItem>> Function(String conversationId, int limit);
typedef MessageOrderInfoQuery =
    Future<MessageOrderInfo?> Function(String messageId);
typedef AroundMessageIdsQuery =
    Future<List<String>> Function(
      MessageOrderInfo anchor,
      String conversationId,
      int limit,
    );
typedef MessagesByIdsQuery =
    Future<List<MessageItem>> Function(
      List<String> messageIds,
    );

class MessageWindowLoader {
  const MessageWindowLoader({
    required this.recentMessages,
    required this.messageOrderInfo,
    required this.beforeMessageIds,
    required this.afterMessageIds,
    required this.messagesByIds,
  });

  factory MessageWindowLoader.fromDao(MessageDao messageDao) =>
      MessageWindowLoader(
        recentMessages: (conversationId, limit) =>
            messageDao.messagesByConversationId(conversationId, limit).get(),
        messageOrderInfo: messageDao.messageOrderInfo,
        beforeMessageIds: (anchor, conversationId, limit) => messageDao
            .beforeMessageIdsByConversationId(anchor, conversationId, limit)
            .get(),
        afterMessageIds: (anchor, conversationId, limit) => messageDao
            .afterMessageIdsByConversationId(anchor, conversationId, limit)
            .get(),
        messagesByIds: (messageIds) =>
            messageDao.messageItemByMessageIds(messageIds).get(),
      );

  final RecentMessagesQuery recentMessages;
  final MessageOrderInfoQuery messageOrderInfo;
  final AroundMessageIdsQuery beforeMessageIds;
  final AroundMessageIdsQuery afterMessageIds;
  final MessagesByIdsQuery messagesByIds;

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
    final bottomIdsFuture = afterMessageIds(info, conversationId, halfLimit);
    final topIdsFuture = beforeMessageIds(info, conversationId, halfLimit);

    final bottomIds = await bottomIdsFuture;
    final topIds = await topIdsFuture;
    final messageIds = [...topIds.reversed, centerMessageId, ...bottomIds];
    final messages = await messagesByIds(messageIds);
    final messagesById = {
      for (final message in messages) message.messageId: message,
    };

    final bottomList = bottomIds
        .map((id) => messagesById[id])
        .nonNulls
        .toList();
    var topList = topIds.reversed
        .map((id) => messagesById[id])
        .nonNulls
        .toList();
    var center = messagesById[centerMessageId];

    final isLatest = bottomIds.length < halfLimit;
    final isOldest = topIds.length < halfLimit;

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
