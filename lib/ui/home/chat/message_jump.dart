import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../bloc/blink_cubit.dart';
import '../bloc/message_bloc.dart';
import 'chat_jump_trace.dart';
import 'chat_scroll_coordinator.dart';

extension ChatMessageJump on BuildContext {
  Future<void> jumpToMessageInChat(String messageId) async {
    traceChatJump('request target=${shortMessageId(messageId)}');
    read<BlinkCubit>().blinkByMessageId(messageId);

    final scrollCoordinator = read<ChatScrollCoordinator>();
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
    scrollCoordinator.nextAnimatedRestoreMessageId = messageId;
    read<MessageBloc>().scrollTo(messageId);
  }
}
