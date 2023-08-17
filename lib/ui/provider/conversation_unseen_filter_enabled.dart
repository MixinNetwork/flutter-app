import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConversationUnseenFilterEnabledNotifier extends StateNotifier<bool> {
  ConversationUnseenFilterEnabledNotifier() : super(false);

  void toggle() => state = !state;

  void reset() => state = false;
}

final conversationUnseenFilterEnabledProvider =
    StateNotifierProvider<ConversationUnseenFilterEnabledNotifier, bool>(
        (ref) => ConversationUnseenFilterEnabledNotifier());
