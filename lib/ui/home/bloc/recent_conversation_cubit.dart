import 'dart:math';

import '../../../bloc/simple_cubit.dart';
import '../../../bloc/subscribe_mixin.dart';

class RecentConversationCubit extends SimpleCubit<List<String>>
    with SubscribeMixin {
  RecentConversationCubit() : super([]);

  void add(String conversationId) {
    final newList = ([...state]
      ..remove(conversationId)
      ..add(conversationId));
    if (newList.isEmpty) return;

    emit(newList.sublist(max(newList.length - 5, 0), newList.length));
  }

  List<String> get reversedState => state.reversed.toList();
}
