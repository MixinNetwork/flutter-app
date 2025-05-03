import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../utils/rivepod.dart';

class RecentConversationIDsNotifier
    extends DistinctStateNotifier<List<String>> {
  RecentConversationIDsNotifier() : super([]);

  void add(String conversationId) {
    final newList =
        ([...state]
          ..remove(conversationId)
          ..add(conversationId));
    if (newList.isEmpty) return;

    state = newList.sublist(max(newList.length - 5, 0), newList.length);
  }

  List<String> get reversedState => state.reversed.toList();
}

final recentConversationIDsProvider = StateNotifierProvider.autoDispose<
  RecentConversationIDsNotifier,
  List<String>
>((ref) {
  ref.keepAlive();
  return RecentConversationIDsNotifier();
});
