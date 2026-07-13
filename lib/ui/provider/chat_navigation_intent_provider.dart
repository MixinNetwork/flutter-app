import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/rivepod.dart';

class ChatNavigationIntentState extends Equatable {
  const ChatNavigationIntentState({
    this.latestJumpRequestKey,
    this.latestJumpConversationId,
  });

  final Object? latestJumpRequestKey;
  final String? latestJumpConversationId;

  @override
  List<Object?> get props => [latestJumpRequestKey, latestJumpConversationId];
}

class ChatNavigationIntentNotifier
    extends DistinctStateNotifier<ChatNavigationIntentState> {
  ChatNavigationIntentNotifier() : super(const ChatNavigationIntentState());

  void requestLatestJump(String conversationId) {
    final latestJumpRequestKey = Object();
    state = ChatNavigationIntentState(
      latestJumpRequestKey: latestJumpRequestKey,
      latestJumpConversationId: conversationId,
    );
  }

  bool takeLatestJump(Object requestKey, String conversationId) {
    if (!identical(state.latestJumpRequestKey, requestKey)) return false;
    final matches =
        state.latestJumpRequestKey != null &&
        state.latestJumpConversationId == conversationId;
    state = const ChatNavigationIntentState();
    return matches;
  }
}

final chatNavigationIntentProvider =
    StateNotifierProvider.autoDispose<
      ChatNavigationIntentNotifier,
      ChatNavigationIntentState
    >((ref) => ChatNavigationIntentNotifier());
