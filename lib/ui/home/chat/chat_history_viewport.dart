import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../../db/mixin_database.dart' hide Offset;
import '../../../utils/extension/extension.dart';
import '../../../widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import '../../../widgets/message/message.dart';
import '../../../widgets/message/message_day_time.dart';
import '../../provider/is_bot_group_provider.dart';
import '../../provider/setting_provider.dart';
import '../notifier/message_controller.dart';
import 'chat_jump_trace.dart';
import 'chat_scroll_coordinator.dart';

@visibleForTesting
void syncMessageGlobalKeys(
  Map<String, GlobalKey> keysByMessageId,
  Set<String> messageIds, {
  GlobalKey Function(String messageId) createKey = _messageGlobalKey,
}) {
  keysByMessageId.removeWhere(
    (messageId, _) => !messageIds.contains(messageId),
  );
  for (final messageId in messageIds) {
    keysByMessageId.putIfAbsent(
      messageId,
      () => createKey(messageId),
    );
  }
}

GlobalKey _messageGlobalKey(String messageId) => MessageGlobalKey(messageId);

GlobalKey _messageDayTimeKey(String messageId) =>
    GlobalKey(debugLabel: 'message day time $messageId');

class ChatHistoryViewport extends HookConsumerWidget {
  const ChatHistoryViewport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = context.read<MessageController>();
    final scrollCoordinator = context.read<ChatScrollCoordinator>();
    final state = useValueListenable(messageController);

    final key = ValueKey((state.conversationId, state.refreshKey));
    final top = state.top;
    final center = state.center;
    final bottom = state.bottom;
    final messages = state.list;
    final anchorUnreadSeparator =
        center != null &&
        center.messageId == state.lastReadMessageId &&
        bottom.isNotEmpty;
    final conversationId = state.conversationId;
    final isBotGroupConversation =
        conversationId != null && ref.watch(isBotGroupProvider(conversationId));
    final enableShowAvatar = ref.watch(
      settingProvider.select((value) => value.messageShowAvatar),
    );
    final rows = useMemoized(
      () {
        final centerMessage = center;
        final renderTop = anchorUnreadSeparator && centerMessage != null
            ? [...top, centerMessage]
            : top;
        final renderCenter = anchorUnreadSeparator ? null : centerMessage;
        return MessageRows.from(
          top: renderTop,
          center: renderCenter,
          bottom: bottom,
        );
      },
      [top, center, bottom, anchorUnreadSeparator],
    );

    final messageKeysRef = useRef<Map<String, GlobalKey>>({});
    final dayTimeKeysRef = useRef<Map<String, GlobalKey>>({});
    final previousConversationIdRef = useRef<String?>(null);
    final previousRefreshKeyRef = useRef<Object?>(null);
    final viewportKey = useMemoized(
      () => GlobalKey(debugLabel: 'chat scroll viewport'),
      [scrollCoordinator],
    );

    final messageIds = messages.map((e) => e.messageId).toSet();
    final messageIdsKey = messages.map((e) => e.messageId).join('|');
    final resetScrollWindow =
        previousConversationIdRef.value != state.conversationId ||
        previousRefreshKeyRef.value != state.refreshKey;

    useEffect(() {
      scrollCoordinator.viewportKey = viewportKey;
      return () => scrollCoordinator.detachViewportKey(viewportKey);
    }, [scrollCoordinator, viewportKey]);

    if (!resetScrollWindow) {
      scrollCoordinator.captureViewportState(messages, messageKeysRef.value);
    }

    useMemoized(() {
      syncMessageGlobalKeys(messageKeysRef.value, messageIds);
      syncMessageGlobalKeys(
        dayTimeKeysRef.value,
        messageIds,
        createKey: _messageDayTimeKey,
      );
    }, [messageIdsKey]);

    final dayTimeEntries = useMemoized(
      () => _dayTimeEntries(rows, messageKeysRef.value, dayTimeKeysRef.value),
      [rows, messageIdsKey],
    );

    Widget buildMessage(MessageRowModel row) {
      final message = row.message;
      final showUnreadBar =
          !anchorUnreadSeparator ||
          message.messageId != state.lastReadMessageId;
      return ChatRenderedMessage(
        coordinator: scrollCoordinator,
        messageId: message.messageId,
        child: MessageItemWidget(
          key: messageKeysRef.value[message.messageId],
          row: row,
          message: message,
          lastReadMessageId: state.lastReadMessageId,
          showUnreadBar: showUnreadBar,
          dateTimeKey: row.dateTime == null
              ? null
              : dayTimeKeysRef.value[message.messageId],
          isGroupOrBotGroupConversation: _isGroupOrBotGroupMessage(
            message,
            isBotGroupConversation,
          ),
          enableShowAvatar: enableShowAvatar,
        ),
      );
    }

    useEffect(
      () {
        final restoreAnchor = anchorUnreadSeparator
            ? ChatScrollCoordinator.unreadSeparatorAnchor
            : ChatScrollCoordinator.messageFocusAnchor;
        traceChatJump(
          'viewport restore-input '
          'conv=${shortMessageId(state.conversationId)} '
          'reset=$resetScrollWindow '
          'unreadAnchor=$anchorUnreadSeparator '
          'anchor=${formatDouble(restoreAnchor)} '
          'lastRead=${shortMessageId(state.lastReadMessageId)} '
          'center=${shortMessageId(center?.messageId)} '
          'top=${top.length} bottom=${bottom.length} '
          'messages=${messages.length} latest=${state.isLatest}',
        );
        scrollCoordinator.scheduleRestore(
          messages: messages,
          keysByMessageId: messageKeysRef.value,
          reset: resetScrollWindow,
          isLatest: state.isLatest,
          hasCenteredAnchor: anchorUnreadSeparator,
          centerMessageId: anchorUnreadSeparator ? null : center?.messageId,
          traceTargetMessageId: center?.messageId ?? state.lastReadMessageId,
        );
        previousConversationIdRef.value = state.conversationId;
        previousRefreshKeyRef.value = state.refreshKey;
        return null;
      },
      [
        state.conversationId,
        state.refreshKey,
        messageIdsKey,
        state.isLatest,
      ],
    );

    return MessageDayTimeViewportWidget.chatPage(
      key: key,
      entries: dayTimeEntries,
      scrollController: scrollCoordinator.scrollController,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) =>
            scrollCoordinator.handleScrollNotification(
              notification,
              messages: messages,
              keysByMessageId: messageKeysRef.value,
              loadBefore: messageController.before,
              loadAfter: messageController.after,
            ),
        child: ClampingCustomScrollView(
          key: viewportKey,
          center: key,
          controller: scrollCoordinator.scrollController,
          anchor: anchorUnreadSeparator
              ? ChatScrollCoordinator.unreadSeparatorAnchor
              : ChatScrollCoordinator.messageFocusAnchor,
          physics: const ClampingScrollPhysics(),
          scrollCacheExtent: const ScrollCacheExtent.viewport(
            ChatScrollCoordinator.loadedJumpViewportCount,
          ),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final actualIndex = rows.top.length - index - 1;
                final row = rows.top[actualIndex];
                return buildMessage(row);
              }, childCount: rows.top.length),
            ),
            SliverToBoxAdapter(
              key: key,
              child: Builder(
                builder: (context) {
                  if (anchorUnreadSeparator) {
                    return const UnreadMessageBar();
                  }
                  final row = rows.center;
                  if (row == null) return const SizedBox();
                  return buildMessage(row);
                },
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final row = rows.bottom[index];
                return buildMessage(row);
              }, childCount: bottom.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }
}

bool _isGroupOrBotGroupMessage(MessageItem message, bool isBotGroup) =>
    message.conversionCategory == ConversationCategory.group ||
    message.userId != message.conversationOwnerId ||
    isBotGroup;

List<MessageDayTimeViewportEntry> _dayTimeEntries(
  MessageRows rows,
  Map<String, GlobalKey> messageKeys,
  Map<String, GlobalKey> dayTimeKeys,
) {
  Iterable<MessageDayTimeViewportEntry> mapRows(
    Iterable<MessageRowModel> rows,
  ) => rows.map((row) {
    final messageId = row.message.messageId;
    return MessageDayTimeViewportEntry(
      message: row.message,
      messageKey: messageKeys[messageId]!,
      dayTimeKey: row.dateTime == null ? null : dayTimeKeys[messageId],
    );
  });

  return [
    ...mapRows(rows.top),
    if (rows.center != null) ...mapRows([rows.center!]),
    ...mapRows(rows.bottom),
  ];
}
