import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'conversation_provider.dart';

final pendingChatJumpProvider = StateProvider.autoDispose<String?>((ref) {
  final keepAlive = ref.keepAlive();

  ref.listen(currentConversationIdProvider, (previous, next) {
    keepAlive.close();
    ref.invalidateSelf();
  });

  return null;
});
