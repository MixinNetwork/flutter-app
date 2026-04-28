import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../db/mixin_database.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../widgets/ai/ai_message_card.dart';
import '../../../../widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import '../../../../widgets/empty.dart';
import '../../../../widgets/message/message_day_time.dart';
import '../../../../widgets/toast.dart';
import 'constants.dart';

class AiAssistantMessageList extends HookWidget {
  const AiAssistantMessageList({
    required this.conversationId,
    required this.latestMessages,
    super.key,
  });

  final String conversationId;
  final List<AiChatMessage> latestMessages;

  @override
  Widget build(BuildContext context) {
    final olderMessages = useState(const <AiChatMessage>[]);
    final isLoadingOlder = useState(false);
    final isOldest = useState(false);
    final messages = useMemoized(
      () => _mergeAiMessages([...olderMessages.value, ...latestMessages]),
      [olderMessages.value, latestMessages],
    );
    final centerKey = useMemoized(
      () => ValueKey('ai-list-center-$conversationId'),
      [conversationId],
    );
    final topKey = useMemoized(
      () => GlobalKey(debugLabel: 'ai list top'),
    );
    final bottomKey = useMemoized(
      () => GlobalKey(debugLabel: 'ai list bottom'),
    );
    final scrollController = useScrollController();
    final lastMessage = messages.lastOrNull;
    final shouldStickToBottomRef = useRef(true);
    final initialMessagesDisplayedRef = useRef(false);
    final lastUserMessageIdRef = useRef<String?>(null);
    final previousLatestMessagesRef = useRef(const <AiChatMessage>[]);

    void scrollToCurrent({required bool animated}) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        if (!position.hasContentDimensions) return;
        if (animated) {
          unawaited(
            scrollController.animateTo(
              position.maxScrollExtent,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
            ),
          );
        } else {
          scrollController.jumpTo(position.maxScrollExtent);
        }
      });
    }

    Future<void> loadOlderMessages() async {
      if (isLoadingOlder.value || isOldest.value || messages.isEmpty) {
        return;
      }

      final before = messages.first;
      isLoadingOlder.value = true;

      try {
        final list = await context.database.aiChatMessageDao
            .beforeConversationMessages(
              conversationId: conversationId,
              before: before,
              limit: aiAssistantMessagePageLimit,
            );
        olderMessages.value = _mergeAiMessages([
          ...list,
          ...olderMessages.value,
        ]);
        isOldest.value = list.length < aiAssistantMessagePageLimit;
      } catch (error, _) {
        showToastFailed(error);
      } finally {
        isLoadingOlder.value = false;
      }
    }

    useEffect(() {
      olderMessages.value = const <AiChatMessage>[];
      isLoadingOlder.value = false;
      isOldest.value = false;
      shouldStickToBottomRef.value = true;
      initialMessagesDisplayedRef.value = false;
      lastUserMessageIdRef.value = null;
      previousLatestMessagesRef.value = const <AiChatMessage>[];
      return null;
    }, [conversationId]);

    useEffect(() {
      final previousLatestMessages = previousLatestMessagesRef.value;
      previousLatestMessagesRef.value = latestMessages;

      if (olderMessages.value.isEmpty ||
          previousLatestMessages.isEmpty ||
          latestMessages.isEmpty) {
        return null;
      }

      final latestIds = latestMessages.map((item) => item.id).toSet();
      final firstLatestMessage = latestMessages.first;
      final droppedMessages = previousLatestMessages
          .where(
            (item) =>
                !latestIds.contains(item.id) &&
                _compareAiMessages(item, firstLatestMessage) < 0,
          )
          .toList(growable: false);
      if (droppedMessages.isNotEmpty) {
        olderMessages.value = _mergeAiMessages([
          ...olderMessages.value,
          ...droppedMessages,
        ]);
      }

      return null;
    }, [latestMessages]);

    useEffect(() {
      if (olderMessages.value.isEmpty) {
        isOldest.value = latestMessages.length < aiAssistantMessagePageLimit;
      }
      return null;
    }, [latestMessages, olderMessages.value]);

    useEffect(() {
      void updateStickToBottom() {
        if (!scrollController.hasClients) return;
        final position = scrollController.position;
        if (!position.hasContentDimensions) return;
        shouldStickToBottomRef.value =
            position.maxScrollExtent - position.pixels <
            aiAssistantStickToBottomDistance;
      }

      scrollController.addListener(updateStickToBottom);
      return () => scrollController.removeListener(updateStickToBottom);
    }, [scrollController]);

    useEffect(() {
      if (messages.isEmpty) return null;
      if (!initialMessagesDisplayedRef.value) {
        initialMessagesDisplayedRef.value = true;
        return null;
      }

      final lastMessageIsUser = lastMessage?.role == 'user';
      final hasNewUserMessage =
          lastMessageIsUser && lastMessage?.id != lastUserMessageIdRef.value;
      if (hasNewUserMessage) {
        lastUserMessageIdRef.value = lastMessage?.id;
        shouldStickToBottomRef.value = true;
      }

      if (!shouldStickToBottomRef.value) return null;
      scrollToCurrent(animated: hasNewUserMessage);
      return null;
    }, [messages.length, lastMessage?.updatedAt, lastMessage?.content]);

    if (messages.isEmpty) {
      return const Empty(text: aiAssistantEmpty);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        shouldStickToBottomRef.value =
            notification.metrics.maxScrollExtent - notification.metrics.pixels <
            aiAssistantStickToBottomDistance;
        if (notification is ScrollUpdateNotification &&
            (notification.scrollDelta ?? 0) < 0) {
          final dimension = notification.metrics.viewportDimension / 2;
          if ((notification.metrics.minScrollExtent -
                      notification.metrics.pixels)
                  .abs() <
              dimension) {
            unawaited(loadOlderMessages());
          }
        }
        return false;
      },
      child: MessageDayTimeViewportWidget.chatPage(
        key: ValueKey(conversationId),
        bottomKey: bottomKey,
        center: null,
        topKey: topKey,
        scrollController: scrollController,
        centerKey: null,
        child: ClampingCustomScrollView(
          key: centerKey,
          center: centerKey,
          controller: scrollController,
          anchor: 0.3,
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList(
                key: topKey,
                delegate: SliverChildBuilderDelegate((
                  context,
                  index,
                ) {
                  final actualIndex = messages.length - index - 1;
                  final message = messages[actualIndex];
                  return MessageDayTimeItem(
                    key: ValueKey('assistant-${message.id}'),
                    dateTime: message.createdAt,
                    prevDateTime: actualIndex > 0
                        ? messages[actualIndex - 1].createdAt
                        : null,
                    child: AiMessageCard(
                      message: message,
                      prev: actualIndex > 0 ? messages[actualIndex - 1] : null,
                      next: actualIndex < messages.length - 1
                          ? messages[actualIndex + 1]
                          : null,
                    ),
                  );
                }, childCount: messages.length),
              ),
            ),
            SliverToBoxAdapter(key: centerKey),
            SliverPadding(
              key: bottomKey,
              padding: const EdgeInsets.only(bottom: 20),
            ),
          ],
        ),
      ),
    );
  }
}

List<AiChatMessage> _mergeAiMessages(Iterable<AiChatMessage> messages) {
  final map = <String, AiChatMessage>{};
  for (final message in messages) {
    map[message.id] = message;
  }
  return map.values.toList(growable: false)..sort(_compareAiMessages);
}

int _compareAiMessages(AiChatMessage a, AiChatMessage b) {
  final createdAtResult = a.createdAt.compareTo(b.createdAt);
  if (createdAtResult != 0) return createdAtResult;
  return a.id.compareTo(b.id);
}
