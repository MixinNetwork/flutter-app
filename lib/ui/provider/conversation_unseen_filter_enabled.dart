import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConversationUnseenFilterEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void reset() => state = false;
}

final conversationUnseenFilterEnabledProvider =
    NotifierProvider<ConversationUnseenFilterEnabledNotifier, bool>(
      ConversationUnseenFilterEnabledNotifier.new,
    );
