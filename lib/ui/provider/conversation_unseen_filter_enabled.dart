import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/rivepod.dart';

class ConversationUnseenFilterEnabledNotifier
    extends DistinctStateNotifier<bool> {
  ConversationUnseenFilterEnabledNotifier() : super(false);

  void toggle() => state = !state;

  void reset() => state = false;
}

final conversationUnseenFilterEnabledProvider =
    StateNotifierProvider<ConversationUnseenFilterEnabledNotifier, bool>(
      (ref) => ConversationUnseenFilterEnabledNotifier(),
    );
