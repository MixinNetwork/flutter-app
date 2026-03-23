import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class RecentConversationIDsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    ref.keepAlive();
    return const [];
  }

  void add(String conversationId) {
    final newList = ([...state]
      ..remove(conversationId)
      ..add(conversationId));
    if (newList.isEmpty) return;

    state = newList.sublist(max(newList.length - 5, 0), newList.length);
  }

  List<String> get reversedState => state.reversed.toList();
}

final recentConversationIDsProvider =
    NotifierProvider.autoDispose<RecentConversationIDsNotifier, List<String>>(
      RecentConversationIDsNotifier.new,
    );
