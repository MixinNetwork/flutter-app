import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../utils/extension/extension.dart';
import '../../provider/quote_message_provider.dart';
import 'message_jump.dart';

@visibleForTesting
class ChatSendOutcome {
  const ChatSendOutcome({
    required Future<void> Function() jumpToLatest,
    required VoidCallback clearQuote,
  }) : _jumpToLatest = jumpToLatest,
       _clearQuote = clearQuote;

  final Future<void> Function() _jumpToLatest;
  final VoidCallback _clearQuote;

  void complete({bool clearQuote = true}) {
    if (clearQuote) _clearQuote();
    unawaited(_jumpToLatest());
  }
}

extension ChatSendOutcomeBuildContext on BuildContext {
  void completeOutgoingChatSend({bool clearQuote = true}) {
    if (!mounted) return;
    ChatSendOutcome(
      clearQuote: () =>
          providerContainer.read(quoteMessageProvider.notifier).state = null,
      jumpToLatest: jumpToLatestInChat,
    ).complete(clearQuote: clearQuote);
  }
}
