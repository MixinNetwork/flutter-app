import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/resources.dart';
import '../../../db/mixin_database.dart' hide Offset;
import '../../../utils/extension/extension.dart';
import '../../../widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import '../../../widgets/interactive_decorated_box.dart';
import '../../../widgets/message/message.dart';
import '../../../widgets/message/message_bubble.dart';
import '../../../widgets/message/message_day_time.dart';
import '../../provider/pending_chat_jump_provider.dart';
import '../notifier/message_controller.dart';
import 'chat_scroll_coordinator.dart';
import 'message_jump.dart';

@visibleForTesting
void syncMessageGlobalKeys(
  Map<String, GlobalKey> keysByMessageId,
  Set<String> messageIds,
) {
  keysByMessageId.removeWhere(
    (messageId, _) => !messageIds.contains(messageId),
  );
  for (final messageId in messageIds) {
    keysByMessageId.putIfAbsent(
      messageId,
      () => MessageGlobalKey(messageId),
    );
  }
}

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
    final rows = useMemoized(
      () => _ChatHistoryRows.from(top: top, center: center, bottom: bottom),
      [top, center, bottom],
    );

    final messageKeysRef = useRef<Map<String, GlobalKey>>({});
    final dayTimeKeysRef = useRef<Map<String, GlobalKey>>({});
    final previousConversationIdRef = useRef<String?>(null);
    final previousRefreshKeyRef = useRef<Object?>(null);

    final messageIds = messages.map((e) => e.messageId).toSet();
    final messageIdsKey = messages.map((e) => e.messageId).join('|');
    final resetScrollWindow =
        previousConversationIdRef.value != state.conversationId ||
        previousRefreshKeyRef.value != state.refreshKey;

    if (!resetScrollWindow) {
      scrollCoordinator.captureViewportState(messages, messageKeysRef.value);
    }

    ref.listen(pendingChatJumpProvider, (previous, next) {
      if (next == null || !next.isCommand) return;
      scheduleMicrotask(() async {
        if (!context.mounted) return;
        final messageId = next.messageId;
        if (messageId == null) {
          await context.jumpToLatestInChat();
        } else {
          await context.jumpToMessageInChat(messageId);
        }
        if (!context.mounted) return;
        ref.read(pendingChatJumpProvider.notifier).state = null;
      });
    });

    useMemoized(() {
      syncMessageGlobalKeys(messageKeysRef.value, messageIds);
      syncMessageGlobalKeys(dayTimeKeysRef.value, messageIds);
    }, [messageIdsKey]);

    final dayTimeEntries = useMemoized(
      () => _dayTimeEntries(rows, messageKeysRef.value, dayTimeKeysRef.value),
      [rows, messageIdsKey],
    );

    useEffect(
      () {
        scrollCoordinator.scheduleRestore(
          messages: messages,
          keysByMessageId: messageKeysRef.value,
          reset: resetScrollWindow,
          isLatest: state.isLatest,
          centerMessageId: center?.messageId,
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
          key: scrollCoordinator.viewportKey,
          center: key,
          controller: scrollCoordinator.scrollController,
          anchor: 0.3,
          physics: const ClampingScrollPhysics(),
          scrollCacheExtent: const ScrollCacheExtent.viewport(
            ChatScrollCoordinator.loadedJumpViewportCount,
          ),
          slivers: [
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final actualIndex = top.length - index - 1;
                final row = rows.top[actualIndex];
                final messageItem = row.message;
                return ChatRenderedMessage(
                  coordinator: scrollCoordinator,
                  messageId: messageItem.messageId,
                  child: MessageItemWidget(
                    key: messageKeysRef.value[messageItem.messageId],
                    row: row,
                    message: messageItem,
                    lastReadMessageId: state.lastReadMessageId,
                    dateTimeKey: row.dateTime == null
                        ? null
                        : dayTimeKeysRef.value[messageItem.messageId],
                  ),
                );
              }, childCount: top.length),
            ),
            SliverToBoxAdapter(
              key: key,
              child: Builder(
                builder: (context) {
                  final row = rows.center;
                  if (row == null) return const SizedBox();
                  final center = row.message;
                  return ChatRenderedMessage(
                    coordinator: scrollCoordinator,
                    messageId: center.messageId,
                    child: MessageItemWidget(
                      key: messageKeysRef.value[center.messageId],
                      row: row,
                      message: center,
                      lastReadMessageId: state.lastReadMessageId,
                      dateTimeKey: row.dateTime == null
                          ? null
                          : dayTimeKeysRef.value[center.messageId],
                    ),
                  );
                },
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final row = rows.bottom[index];
                final messageItem = row.message;
                return ChatRenderedMessage(
                  coordinator: scrollCoordinator,
                  messageId: messageItem.messageId,
                  child: MessageItemWidget(
                    key: messageKeysRef.value[messageItem.messageId],
                    row: row,
                    message: messageItem,
                    lastReadMessageId: state.lastReadMessageId,
                    dateTimeKey: row.dateTime == null
                        ? null
                        : dayTimeKeysRef.value[messageItem.messageId],
                  ),
                );
              }, childCount: bottom.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      ),
    );
  }
}

List<MessageDayTimeViewportEntry> _dayTimeEntries(
  _ChatHistoryRows rows,
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

class _ChatHistoryRows {
  const _ChatHistoryRows({
    required this.top,
    required this.bottom,
    this.center,
  });

  factory _ChatHistoryRows.from({
    required List<MessageItem> top,
    required MessageItem? center,
    required List<MessageItem> bottom,
  }) => _ChatHistoryRows(
    top: [
      for (var index = 0; index < top.length; index++)
        MessageRowModel(
          message: top[index],
          prev: top.getOrNull(index - 1),
          next: top.getOrNull(index + 1) ?? center ?? bottom.lastOrNull,
        ),
    ],
    center: center == null
        ? null
        : MessageRowModel(
            message: center,
            prev: top.lastOrNull,
            next: bottom.firstOrNull,
          ),
    bottom: [
      for (var index = 0; index < bottom.length; index++)
        MessageRowModel(
          message: bottom[index],
          prev: bottom.getOrNull(index - 1) ?? center ?? top.lastOrNull,
          next: bottom.getOrNull(index + 1),
        ),
    ],
  );

  final List<MessageRowModel> top;
  final MessageRowModel? center;
  final List<MessageRowModel> bottom;
}

class JumpCurrentButton extends HookConsumerWidget {
  const JumpCurrentButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollCoordinator = context.read<ChatScrollCoordinator>();

    final state = useValueListenable(context.read<MessageController>());
    final showJumpToLatest = useValueListenable(
      scrollCoordinator.showJumpToLatest,
    );

    final enable = (!state.isEmpty && !state.isLatest) || showJumpToLatest;

    final pendingJumpController = ref.read(pendingChatJumpProvider.notifier);

    if (!enable) {
      Future(() => pendingJumpController.state = null);
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InteractiveDecoratedBox(
        onTap: () async {
          final messageId = pendingJumpController.state?.returnMessageId;
          if (messageId != null) {
            await context.jumpToMessageInChat(messageId);
            pendingJumpController.state = null;
            return;
          }
          await context.jumpToLatestInChat();
        },
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: context.messageBubbleColor(false),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            Resources.assetsImagesJumpCurrentArrowSvg,
            colorFilter: ColorFilter.mode(context.theme.text, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
