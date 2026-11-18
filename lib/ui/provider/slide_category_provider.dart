import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/rivepod.dart';

enum SlideCategoryType {
  chats,
  contacts,
  groups,
  bots,
  strangers,
  circle,
  setting,
  wallet;

  /// Whether the center page shows a conversation list for this category.
  bool get hasConversations => this != setting && this != wallet;
}

class SlideCategoryState extends Equatable {
  const SlideCategoryState({required this.type, this.id});

  final SlideCategoryType type;

  // conversation id or circle id
  final String? id;

  @override
  List<Object?> get props => [type, id];
}

class SlideCategoryStateNotifier
    extends DistinctStateNotifier<SlideCategoryState> {
  SlideCategoryStateNotifier()
    : super(const SlideCategoryState(type: SlideCategoryType.chats));

  void select(SlideCategoryType type, [String? id]) =>
      state = SlideCategoryState(type: type, id: id);

  void switchToChatsIfNoConversations() {
    if (state.type.hasConversations) return;
    select(SlideCategoryType.chats);
  }
}

final slideCategoryStateProvider =
    StateNotifierProvider<SlideCategoryStateNotifier, SlideCategoryState>(
      (ref) => SlideCategoryStateNotifier(),
    );
