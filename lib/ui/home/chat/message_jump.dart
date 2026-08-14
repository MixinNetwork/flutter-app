import 'package:flutter/widgets.dart';

import '../../../utils/extension/extension.dart';
import '../desktop_shell_layout.dart';
import '../notifier/blink_notifier.dart';
import '../notifier/chat_side_notifier.dart';
import '../notifier/message_controller.dart';
import 'chat_jump_trace.dart';
import 'chat_scroll_coordinator.dart';

class ChatTimelineLocation {
  ChatTimelineLocation({
    required BlinkNotifier blinkNotifier,
    required ChatScrollCoordinator scrollCoordinator,
    required MessageController messageController,
  }) : _blinkNotifier = blinkNotifier,
       _scrollCoordinator = scrollCoordinator,
       _messageController = messageController;

  final BlinkNotifier _blinkNotifier;
  final ChatScrollCoordinator _scrollCoordinator;
  final MessageController _messageController;

  Future<void> jumpToMessage(
    String messageId, {
    required ChatSideNotifier chatSideNotifier,
    String? sourceMessageId,
    bool closeSideAfterJump = false,
    bool chatSideRouteMode = false,
  }) async {
    traceChatJump(
      'request source=${shortMessageId(sourceMessageId)} '
      'target=${shortMessageId(messageId)}',
    );
    final handled = await _scrollCoordinator.scrollToMessageIfInLoadedWindow(
      messageId,
      animated: true,
    );
    traceChatJump(
      'loaded-window result target=${shortMessageId(messageId)} '
      'handled=$handled',
    );
    if (handled) {
      _blinkNotifier.blinkByMessageId(messageId);
      _closeSideIfNeeded(
        closeSideAfterJump,
        chatSideRouteMode,
        chatSideNotifier,
      );
      return;
    }

    traceChatJump('reload-window target=${shortMessageId(messageId)}');
    final directionSourceMessageId =
        sourceMessageId ??
        _currentWindowSourceMessageId(_messageController.state);
    final direction = _toScrollDirection(
      await _messageController.restoreDirectionFromSource(
        sourceMessageId: directionSourceMessageId,
        targetMessageId: messageId,
      ),
    );
    traceChatJump(
      'restore direction source=${shortMessageId(directionSourceMessageId)} '
      'target=${shortMessageId(messageId)} direction=$direction',
    );
    _scrollCoordinator.animateNextMessageRestore(
      messageId,
      direction: direction,
      onComplete: () => _blinkNotifier.blinkByMessageId(messageId),
    );
    _messageController.loadAroundMessage(messageId);
    _closeSideIfNeeded(
      closeSideAfterJump,
      chatSideRouteMode,
      chatSideNotifier,
    );
  }

  Future<void> jumpToLatest({
    required ChatSideNotifier chatSideNotifier,
    bool closeSideAfterJump = false,
    bool chatSideRouteMode = false,
  }) async {
    traceChatJump('request latest');
    if (_messageController.state.isLatest &&
        await _scrollCoordinator.scrollToBottomIfInLoadedWindow(
          animated: true,
        )) {
      traceChatJump('loaded-window latest handled=true');
      _closeSideIfNeeded(
        closeSideAfterJump,
        chatSideRouteMode,
        chatSideNotifier,
      );
      return;
    }

    traceChatJump('reload-window latest');
    _scrollCoordinator.animateNextRestore(
      direction: ChatScrollRestoreDirection.towardNewer,
    );
    _messageController.loadLatestWindow();
    _closeSideIfNeeded(
      closeSideAfterJump,
      chatSideRouteMode,
      chatSideNotifier,
    );
  }

  String? _currentWindowSourceMessageId(MessageState state) {
    if (state.center != null) return state.center!.messageId;
    return state.bottomMessage?.messageId ?? state.topMessage?.messageId;
  }

  ChatScrollRestoreDirection? _toScrollDirection(
    MessageWindowDirection? direction,
  ) => switch (direction) {
    MessageWindowDirection.older => ChatScrollRestoreDirection.towardOlder,
    MessageWindowDirection.newer => ChatScrollRestoreDirection.towardNewer,
    null => null,
  };

  void _closeSideIfNeeded(
    bool closeSideAfterJump,
    bool chatSideRouteMode,
    ChatSideNotifier chatSideNotifier,
  ) {
    if (!closeSideAfterJump) return;
    chatSideNotifier.closeAfterContentJump(routeMode: chatSideRouteMode);
  }
}

extension ChatMessageJump on BuildContext {
  Future<void> jumpToMessageInChat(
    String messageId, {
    String? sourceMessageId,
    bool closeSideAfterJump = false,
  }) {
    final routeMode = DesktopShellLayout.chatSideRouteModeOf(this);
    final chatSideNotifier = read<ChatSideNotifier>();
    return _chatHistoryLocation.jumpToMessage(
      messageId,
      sourceMessageId: sourceMessageId,
      closeSideAfterJump: closeSideAfterJump,
      chatSideRouteMode: routeMode,
      chatSideNotifier: chatSideNotifier,
    );
  }

  Future<void> jumpToLatestInChat({bool closeSideAfterJump = false}) {
    final chatSideNotifier = read<ChatSideNotifier>();
    return _chatHistoryLocation.jumpToLatest(
      closeSideAfterJump: closeSideAfterJump,
      chatSideRouteMode: DesktopShellLayout.chatSideRouteModeOf(this),
      chatSideNotifier: chatSideNotifier,
    );
  }

  ChatTimelineLocation get _chatHistoryLocation => read<ChatTimelineLocation>();
}
