import 'package:equatable/equatable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum SlideCategoryType {
  chats,
  contacts,
  groups,
  bots,
  strangers,
  circle,
  setting,
}

class SlideCategoryState extends Equatable {
  const SlideCategoryState({
    required this.type,
    this.id,
  });

  final SlideCategoryType type;

  // conversation id or circle id
  final String? id;

  @override
  List<Object?> get props => [type, id];
}

class SlideCategoryStateNotifier extends StateNotifier<SlideCategoryState> {
  SlideCategoryStateNotifier()
      : super(const SlideCategoryState(type: SlideCategoryType.chats));

  @override
  SlideCategoryState get state => super.state;

  void select(SlideCategoryType type, [String? id]) =>
      state = SlideCategoryState(type: type, id: id);

  void switchToChatsIfSettings() {
    if (state.type != SlideCategoryType.setting) return;
    select(SlideCategoryType.chats);
  }
}

final slideCategoryStateProvider =
    StateNotifierProvider<SlideCategoryStateNotifier, SlideCategoryState>(
        (ref) => SlideCategoryStateNotifier());
