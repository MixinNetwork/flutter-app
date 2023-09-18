import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../db/mixin_database.dart';
import '../../utils/rivepod.dart';
import 'conversation_provider.dart';

final quoteMessageProvider = StateProvider.autoDispose<MessageItem?>((ref) {
  final keepAlive = ref.keepAlive();

  ref.listen(currentConversationIdProvider, (previous, next) {
    keepAlive.close();
    ref.invalidateSelf();
  });

  return null;
});

final quoteMessageIdProvider =
    quoteMessageProvider.select((message) => message?.messageId);

class LastQuoteMessageStateNotifier
    extends DistinctStateNotifier<MessageItem?> {
  LastQuoteMessageStateNotifier(super.state);

  set _state(MessageItem? value) => super.state = value;
}

final lastQuoteMessageProvider = StateNotifierProvider.autoDispose<
    LastQuoteMessageStateNotifier, MessageItem?>((ref) {
  final lastQuoteMessageStateNotifier =
      LastQuoteMessageStateNotifier(ref.read(quoteMessageProvider));

  ref.listen(quoteMessageProvider, (previous, next) {
    if (next == null) return;
    lastQuoteMessageStateNotifier._state = next;
  });

  return lastQuoteMessageStateNotifier;
});
