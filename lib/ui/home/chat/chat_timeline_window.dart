import '../../../db/mixin_database.dart';
import '../../../widgets/message/message_rows.dart';
import '../notifier/message_controller.dart';
import 'chat_scroll_coordinator.dart';

class ChatTimelineWindow {
  ChatTimelineWindow(this.state)
    : anchorUnreadSeparator =
          state.center != null &&
          state.center!.messageId == state.lastReadMessageId &&
          state.bottom.isNotEmpty {
    final centerMessage = state.center;
    final renderTop = anchorUnreadSeparator && centerMessage != null
        ? [...state.top, centerMessage]
        : state.top;
    rows = MessageRows.from(
      top: renderTop,
      center: anchorUnreadSeparator ? null : centerMessage,
      bottom: state.bottom,
    );
  }

  final MessageState state;
  final bool anchorUnreadSeparator;
  late final MessageRows rows;

  List<MessageItem> get messages => state.list;

  double get scrollAnchor => anchorUnreadSeparator
      ? ChatScrollCoordinator.unreadSeparatorAnchor
      : ChatScrollCoordinator.messageFocusAnchor;

  String? get restoreCenterMessageId =>
      anchorUnreadSeparator ? null : state.center?.messageId;

  String? get traceTargetMessageId =>
      state.center?.messageId ?? state.lastReadMessageId;

  bool resetScrollWindow({
    required String? previousConversationId,
    required Object? previousRefreshKey,
  }) =>
      previousConversationId != state.conversationId ||
      previousRefreshKey != state.refreshKey;

  bool resetCurrentConversation({
    required String? previousConversationId,
    required Object? previousRefreshKey,
  }) =>
      previousConversationId == state.conversationId &&
      previousRefreshKey != state.refreshKey;

  bool animateLatestReset({
    required String? previousConversationId,
    required Object? previousRefreshKey,
  }) =>
      resetCurrentConversation(
        previousConversationId: previousConversationId,
        previousRefreshKey: previousRefreshKey,
      ) &&
      state.isLatest &&
      state.center == null &&
      !anchorUnreadSeparator;
}
