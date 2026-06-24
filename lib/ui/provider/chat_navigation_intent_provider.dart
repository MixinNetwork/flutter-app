import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/rivepod.dart';

class ChatNavigationIntentState extends Equatable {
  const ChatNavigationIntentState({this.latestJumpRequestKey});

  final Object? latestJumpRequestKey;

  @override
  List<Object?> get props => [latestJumpRequestKey];
}

class ChatNavigationIntentNotifier
    extends DistinctStateNotifier<ChatNavigationIntentState> {
  ChatNavigationIntentNotifier() : super(const ChatNavigationIntentState());

  void requestLatestJump() {
    final latestJumpRequestKey = Object();
    state = ChatNavigationIntentState(
      latestJumpRequestKey: latestJumpRequestKey,
    );
  }
}

final chatNavigationIntentProvider =
    StateNotifierProvider.autoDispose<
      ChatNavigationIntentNotifier,
      ChatNavigationIntentState
    >((ref) => ChatNavigationIntentNotifier());
