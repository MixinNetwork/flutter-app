import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../utils/extension/extension.dart';
import '../bloc/blink_cubit.dart';
import '../bloc/message_bloc.dart';
import 'chat_jump_trace.dart';
import 'chat_scroll_coordinator.dart';

extension ChatMessageJump on BuildContext {
  Future<void> jumpToMessageInChat(
    String messageId, {
    String? sourceMessageId,
  }) async {
    traceChatJump(
      'request source=${shortMessageId(sourceMessageId)} '
      'target=${shortMessageId(messageId)}',
    );
    read<BlinkCubit>().blinkByMessageId(messageId);

    final scrollCoordinator = read<ChatScrollCoordinator>();
    final messageBloc = read<MessageBloc>();
    final handled = await scrollCoordinator.scrollToMessageIfInLoadedWindow(
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
        sourceMessageId ?? _currentWindowSourceMessageId(messageBloc.state);
    final direction = await _restoreDirectionFromSource(
      sourceMessageId: directionSourceMessageId,
      targetMessageId: messageId,
    );
    traceChatJump(
      'restore direction source=${shortMessageId(directionSourceMessageId)} '
      'target=${shortMessageId(messageId)} direction=$direction',
    );
    scrollCoordinator.animateNextMessageRestore(
      messageId,
      direction: direction,
    );
    messageBloc.scrollTo(messageId);
  }

  Future<void> jumpToLatestInChat() async {
    traceChatJump('request latest');
    final scrollCoordinator = read<ChatScrollCoordinator>();
    if (await scrollCoordinator.scrollToBottomIfInLoadedWindow(
      animated: true,
    )) {
      traceChatJump('loaded-window latest handled=true');
      return;
    }

    traceChatJump('reload-window latest');
    scrollCoordinator.animateNextRestore(
      direction: ChatScrollRestoreDirection.towardNewer,
    );
    read<MessageBloc>().jumpToLatestWindow();
  }

  void popChatSideRouteIfNeeded() {
    if (ModalRoute.of(this)?.canPop != true) return;
    unawaited(Navigator.maybePop(this));
  }

  String? _currentWindowSourceMessageId(MessageState state) {
    if (state.center != null) return state.center!.messageId;
    return state.bottomMessage?.messageId ?? state.topMessage?.messageId;
  }

  Future<ChatScrollRestoreDirection?> _restoreDirectionFromSource({
    required String? sourceMessageId,
    required String targetMessageId,
  }) async {
    if (sourceMessageId == null || sourceMessageId == targetMessageId) {
      return null;
    }

    final messageDao = database.messageDao;
    final results = await Future.wait([
      messageDao.messageOrderInfo(sourceMessageId),
      messageDao.messageOrderInfo(targetMessageId),
    ]);
    final sourceInfo = results[0];
    final targetInfo = results[1];
    if (sourceInfo == null || targetInfo == null) return null;

    final sourceAfterTarget = sourceInfo.createdAt == targetInfo.createdAt
        ? sourceInfo.rowId > targetInfo.rowId
        : sourceInfo.createdAt > targetInfo.createdAt;
    return sourceAfterTarget
        ? ChatScrollRestoreDirection.towardOlder
        : ChatScrollRestoreDirection.towardNewer;
  }
}
