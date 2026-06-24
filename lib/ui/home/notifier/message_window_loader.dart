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
typedef AroundMessagesQuery =
    Future<List<MessageItem>> Function(
      MessageOrderInfo anchor,
      String conversationId,
      int limit,
    );
typedef MessagesByIdsQuery =
    Future<List<MessageItem>> Function(
      List<String> messageIds,
    );

enum MessageWindowDirection { older, newer }

class MessageWindowLoader {
  const MessageWindowLoader({
    required this.recentMessages,
    required this.messageOrderInfo,
    required this.beforeMessages,
    required this.afterMessages,
    required this.beforeMessageIds,
    required this.afterMessageIds,
    required this.messagesByIds,
  });

  factory MessageWindowLoader.fromDao(MessageDao messageDao) {
    Future<List<MessageItem>> messagesByIds(List<String> ids) async {
      if (ids.isEmpty) return const [];
      final messages = await messageDao.messageItemByMessageIds(ids).get();
      final messagesById = {
        for (final message in messages) message.messageId: message,
      };
      return ids.map((id) => messagesById[id]).nonNulls.toList();
    }

    return MessageWindowLoader(
      recentMessages: (conversationId, limit) =>
          messageDao.messagesByConversationId(conversationId, limit).get(),
      messageOrderInfo: messageDao.messageOrderInfo,
      beforeMessages: (anchor, conversationId, limit) async {
        final ids = await messageDao.beforeMessageIdsByConversationId(
          anchor,
          conversationId,
          limit,
        );
        return messagesByIds(ids);
      },
      afterMessages: (anchor, conversationId, limit) async {
        final ids = await messageDao.afterMessageIdsByConversationId(
          anchor,
          conversationId,
          limit,
        );
        return messagesByIds(ids);
      },
      beforeMessageIds: (anchor, conversationId, limit) => messageDao
          .beforeMessageIdsByConversationId(anchor, conversationId, limit),
      afterMessageIds: (anchor, conversationId, limit) => messageDao
          .afterMessageIdsByConversationId(anchor, conversationId, limit),
      messagesByIds: messagesByIds,
    );
  }

  final RecentMessagesQuery recentMessages;
  final MessageOrderInfoQuery messageOrderInfo;
  final AroundMessagesQuery beforeMessages;
  final AroundMessagesQuery afterMessages;
  final AroundMessageIdsQuery beforeMessageIds;
  final AroundMessageIdsQuery afterMessageIds;
  final MessagesByIdsQuery messagesByIds;

  Future<MessageState> loadBefore(
    MessageState state,
    String conversationId,
    int limit,
  ) async {
    final topMessageId = state.topMessage?.messageId;
    if (topMessageId == null) return state.copyWith(isOldest: true);

    final info = await messageOrderInfo(topMessageId);
    if (info == null) return state.copyWith(isOldest: true);

    final messages = await beforeMessages(info, conversationId, limit);
    return state.copyWith(
      top: [...messages.reversed, ...state.top],
      isOldest: messages.length < limit,
    );
  }

  Future<MessageState> loadAfter(
    MessageState state,
    String conversationId,
    int limit,
  ) async {
    final bottomMessageId = state.bottomMessage?.messageId;
    if (bottomMessageId == null) return state.copyWith(isLatest: true);

    final info = await messageOrderInfo(bottomMessageId);
    if (info == null) return state.copyWith(isLatest: true);

    final messages = await afterMessages(info, conversationId, limit);
    return state.copyWith(
      bottom: [...state.bottom, ...messages],
      isLatest: messages.length < limit ? true : null,
    );
  }

  Future<MessageWindowDirection?> directionFromSource({
    required String? sourceMessageId,
    required String targetMessageId,
  }) async {
    if (sourceMessageId == null || sourceMessageId == targetMessageId) {
      return null;
    }

    final results = await Future.wait([
      messageOrderInfo(sourceMessageId),
      messageOrderInfo(targetMessageId),
    ]);
    final sourceInfo = results[0];
    final targetInfo = results[1];
    if (sourceInfo == null || targetInfo == null) return null;

    final sourceAfterTarget = sourceInfo.createdAt == targetInfo.createdAt
        ? sourceInfo.rowId > targetInfo.rowId
        : sourceInfo.createdAt > targetInfo.createdAt;
    return sourceAfterTarget
        ? MessageWindowDirection.older
        : MessageWindowDirection.newer;
  }

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
    trace?.call(
      'query center order target=${shortMessageId(centerMessageId)} '
      'createdAt=${info.createdAt} rowId=${info.rowId} half=$halfLimit',
    );
    final bottomIdsFuture = afterMessageIds(info, conversationId, halfLimit);
    final topIdsFuture = beforeMessageIds(info, conversationId, halfLimit);

    final bottomIds = await bottomIdsFuture;
    final topIds = await topIdsFuture;
    trace?.call(
      'query center ids target=${shortMessageId(centerMessageId)} '
      'top=${topIds.length} '
      'topFirst=${shortMessageId(topIds.firstOrNull)} '
      'topLast=${shortMessageId(topIds.lastOrNull)} '
      'bottom=${bottomIds.length} '
      'bottomFirst=${shortMessageId(bottomIds.firstOrNull)} '
      'bottomLast=${shortMessageId(bottomIds.lastOrNull)}',
    );
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
