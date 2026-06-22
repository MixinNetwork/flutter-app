import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'conversation_provider.dart';

final pendingChatJumpProvider = StateProvider.autoDispose<PendingChatJump?>((
  ref,
) {
  final keepAlive = ref.keepAlive();

  ref.listen(currentConversationIdProvider, (previous, next) {
    keepAlive.close();
    ref.invalidateSelf();
  });

  return null;
});

class PendingChatJump {
  const PendingChatJump.commandMessage(this.messageId)
    : kind = PendingChatJumpKind.command;

  const PendingChatJump.commandLatest()
    : kind = PendingChatJumpKind.command,
      messageId = null;

  const PendingChatJump.returnToMessage(this.messageId)
    : kind = PendingChatJumpKind.returnTarget;

  final PendingChatJumpKind kind;

  final String? messageId;

  bool get isLatest => messageId == null;

  bool get isCommand => kind == PendingChatJumpKind.command;

  String? get returnMessageId =>
      kind == PendingChatJumpKind.returnTarget ? messageId : null;
}

enum PendingChatJumpKind { command, returnTarget }
