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
  const PendingChatJump.returnToMessage(this.messageId);

  final String? messageId;

  String? get returnMessageId => messageId;
}
