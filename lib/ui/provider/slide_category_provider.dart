import 'dart:async';

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
  const SlideCategoryState({required this.type, this.id});

  final SlideCategoryType type;

  // conversation id or circle id
  final String? id;

  @override
  List<Object?> get props => [type, id];
}

class SlideCategoryStateNotifier extends Notifier<SlideCategoryState> {
  late final StreamController<SlideCategoryState> _streamController =
      StreamController<SlideCategoryState>.broadcast();

  Stream<SlideCategoryState> get stream => _streamController.stream;

  @override
  SlideCategoryState build() {
    ref.onDispose(_streamController.close);
    return const SlideCategoryState(type: SlideCategoryType.chats);
  }

  void select(SlideCategoryType type, [String? id]) {
    state = SlideCategoryState(type: type, id: id);
    _streamController.add(state);
  }

  void switchToChatsIfSettings() {
    if (state.type != SlideCategoryType.setting) return;
    select(SlideCategoryType.chats);
  }
}

final slideCategoryProvider =
    NotifierProvider<SlideCategoryStateNotifier, SlideCategoryState>(
      SlideCategoryStateNotifier.new,
    );
