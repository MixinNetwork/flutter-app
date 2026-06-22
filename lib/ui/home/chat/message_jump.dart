import 'package:flutter/widgets.dart';

import '../../../utils/extension/extension.dart';
import '../desktop_shell_layout.dart';
import '../notifier/blink_notifier.dart';
import '../notifier/chat_side_notifier.dart';
import '../notifier/message_controller.dart';
import 'chat_jump_trace.dart';
import 'chat_scroll_coordinator.dart';

bool shouldUseLoadedLatestWindowForLatestJump(MessageState state) =>
    state.isLatest;

enum ChatJumpKind { message, latest }

class ChatJumpTarget {
  const ChatJumpTarget.message(
    this.messageId, {
    this.sourceMessageId,
    this.closeSideAfterJump = false,
  }) : kind = ChatJumpKind.message;

  const ChatJumpTarget.latest({this.closeSideAfterJump = false})
    : kind = ChatJumpKind.latest,
      messageId = null,
      sourceMessageId = null;

  final ChatJumpKind kind;
  final String? messageId;
  final String? sourceMessageId;
  final bool closeSideAfterJump;
}

class ChatHistoryLocation {
  ChatHistoryLocation({
    required BlinkNotifier blinkNotifier,
    required ChatScrollCoordinator scrollCoordinator,
    required MessageController messageController,
    required ChatSideNotifier chatSideNotifier,
    required bool chatSideRouteMode,
  }) : _blinkNotifier = blinkNotifier,
       _scrollCoordinator = scrollCoordinator,
       _messageController = messageController,
       _chatSideNotifier = chatSideNotifier,
       _chatSideRouteMode = chatSideRouteMode;

  final BlinkNotifier _blinkNotifier;
  final ChatScrollCoordinator _scrollCoordinator;
  final MessageController _messageController;
  final ChatSideNotifier _chatSideNotifier;
  final bool _chatSideRouteMode;

  Future<void> jumpTo(ChatJumpTarget target) async {
    switch (target.kind) {
      case ChatJumpKind.message:
        await _jumpToMessage(
          target.messageId!,
          sourceMessageId: target.sourceMessageId,
        );
      case ChatJumpKind.latest:
        await _jumpToLatest();
    }
    if (target.closeSideAfterJump) {
      _chatSideNotifier.closeAfterContentJump(routeMode: _chatSideRouteMode);
    }
  }

  Future<void> _jumpToMessage(
    String messageId, {
    String? sourceMessageId,
  }) async {
    traceChatJump(
      'request source=${shortMessageId(sourceMessageId)} '
      'target=${shortMessageId(messageId)}',
    );
    _blinkNotifier.blinkByMessageId(messageId);

    final handled = await _scrollCoordinator.scrollToMessageIfInLoadedWindow(
      messageId,
      animated: true,
    );
    traceChatJump(
      'loaded-window result target=${shortMessageId(messageId)} '
      'handled=$handled',
    );
    if (handled) {
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
    );
    _messageController.scrollTo(messageId);
  }

  Future<void> _jumpToLatest() async {
    traceChatJump('request latest');
    if (shouldUseLoadedLatestWindowForLatestJump(_messageController.state) &&
        await _scrollCoordinator.scrollToBottomIfInLoadedWindow(
          animated: true,
        )) {
      traceChatJump('loaded-window latest handled=true');
      return;
    }

    traceChatJump('reload-window latest');
    _scrollCoordinator.animateNextRestore(
      direction: ChatScrollRestoreDirection.towardNewer,
    );
    _messageController.jumpToLatestWindow();
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
}

extension ChatMessageJump on BuildContext {
  Future<void> jumpToChatTarget(ChatJumpTarget target) =>
      _chatHistoryLocation.jumpTo(target);

  Future<void> jumpToMessageInChat(
    String messageId, {
    String? sourceMessageId,
    bool closeSideAfterJump = false,
  }) => jumpToChatTarget(
    ChatJumpTarget.message(
      messageId,
      sourceMessageId: sourceMessageId,
      closeSideAfterJump: closeSideAfterJump,
    ),
  );

  Future<void> jumpToLatestInChat({bool closeSideAfterJump = false}) =>
      jumpToChatTarget(
        ChatJumpTarget.latest(closeSideAfterJump: closeSideAfterJump),
      );

  ChatHistoryLocation get _chatHistoryLocation => ChatHistoryLocation(
    blinkNotifier: read<BlinkNotifier>(),
    scrollCoordinator: read<ChatScrollCoordinator>(),
    messageController: read<MessageController>(),
    chatSideNotifier: read<ChatSideNotifier>(),
    chatSideRouteMode: DesktopShellLayout.chatSideRouteModeOf(this),
  );
}
