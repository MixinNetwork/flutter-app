import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/users_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/participants_cubit.dart';
import 'package:rxdart/rxdart.dart';

import 'multi_auth_cubit.dart';

class MentionState extends Equatable {
  const MentionState({
    this.text,
    this.users = const [],
    this.index = 0,
  });

  final String? text;
  final List<User> users;
  final int index;

  @override
  List<Object?> get props => [text, users, index];

  MentionState copyWith({
    final String? text,
    final List<User>? users,
    final int? index,
  }) {
    return MentionState(
      text: text ?? this.text,
      users: users ?? this.users,
      index: index ?? this.index,
    );
  }
}

class MentionCubit extends Cubit<MentionState> with SubscribeMixin {
  MentionCubit({
    required this.userDao,
    required this.multiAuthCubit,
    required this.participantsCubit,
  }) : super(const MentionState()) {
    addSubscription(
      streamController.stream.distinct().listen((index) {
        if (!scrollController.hasClients) return;
        scrollController.jumpTo(0);
      }),
    );
    addSubscription(
      Rx.combineLatest2<String?, List<User>, MentionState>(
        streamController.stream,
        participantsCubit,
        (a, b) => MentionState(
          text: a,
          users: a != null
              ? participantsCubit.state
                  .where(
                    (user) =>
                        (user.fullName?.contains(a) ?? false) ||
                        user.identityNumber.contains(a),
                  )
                  .toList()
              : [],
          index: 0,
        ),
      ).listen(emit),
    );
  }

  void _jumpToPosition(int index) {
    const itemHeight = 48;
    final outUp = itemHeight * index <= scrollController.offset;
    final outDown =
        scrollController.position.maxScrollExtent + scrollController.offset <=
            itemHeight * (index + 1);
    if (outUp) {
      scrollController.jumpTo((itemHeight * index).toDouble());
    } else if (outDown) {
      scrollController.jumpTo(
          (itemHeight * (index + 1) - scrollController.position.maxScrollExtent)
              .toDouble());
    }
  }

  final UserDao userDao;
  final MultiAuthCubit multiAuthCubit;
  final ParticipantsCubit participantsCubit;
  final streamController = StreamController<String?>.broadcast();
  final scrollController = ScrollController();

  @override
  Future<void> close() async {
    await streamController.close();
    scrollController.dispose();
    await super.close();
  }

  void send(String? keyword) => streamController.add(keyword);

  void next() {
    final index = math.min(state.index + 1, state.users.length - 1);
    emit(state.copyWith(
      index: index,
    ));
    _jumpToPosition(index);
  }

  void prev() {
    final index = math.max(state.index - 1, 0);
    emit(state.copyWith(
      index: index,
    ));
    _jumpToPosition(index);
  }
}
