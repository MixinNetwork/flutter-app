import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';

import '../../db/mixin_database.dart';
import 'conversation_provider.dart';

class QuoteMessageNotifier extends Notifier<MessageItem?> {
  KeepAliveLink? _keepAlive;

  @override
  MessageItem? build() {
    ref.listen(currentConversationIdProvider, (previous, next) {
      _keepAlive?.close();
      _keepAlive = null;
      state = null;
    });
    return null;
  }

  void set(MessageItem? value) {
    if (value == null) {
      _keepAlive?.close();
      _keepAlive = null;
    } else {
      _keepAlive ??= ref.keepAlive();
    }
    state = value;
  }

  void clear() => set(null);
}

final quoteMessageProvider =
    NotifierProvider.autoDispose<QuoteMessageNotifier, MessageItem?>(
      QuoteMessageNotifier.new,
    );

final quoteMessageIdProvider = quoteMessageProvider.select(
  (message) => message?.messageId,
);

class LastQuoteMessageNotifier extends Notifier<MessageItem?> {
  @override
  MessageItem? build() {
    ref.listen<MessageItem?>(quoteMessageProvider, (previous, next) {
      if (next != null) {
        state = next;
      }
    });
    return ref.read(quoteMessageProvider);
  }
}

final lastQuoteMessageProvider =
    NotifierProvider.autoDispose<LastQuoteMessageNotifier, MessageItem?>(
      LastQuoteMessageNotifier.new,
    );
