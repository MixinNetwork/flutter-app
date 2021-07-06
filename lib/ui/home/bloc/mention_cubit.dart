import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../../../bloc/subscribe_mixin.dart';
import '../../../db/dao/user_dao.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/reg_exp_utils.dart';
import '../../../utils/sort.dart';
import '../../../widgets/mention_panel.dart';
import 'multi_auth_cubit.dart';
import 'participants_cubit.dart';

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
  }) =>
      MentionState(
        text: text ?? this.text,
        users: users ?? this.users,
        index: index ?? this.index,
      );
}

class MentionCubit extends Cubit<MentionState> with SubscribeMixin {
  MentionCubit({
    required this.userDao,
    required this.multiAuthCubit,
    required this.participantsCubit,
  }) : super(const MentionState());

  Future<void> setTextEditingValueStream(
    Stream<TextEditingValue> textEditingValueStream,
    TextEditingValue initialValue,
  ) async {
    subscriptions
      ..forEach((subscription) => subscription?.cancel())
      ..clear();

    final mentionTextStream =
        textEditingValueStream.startWith(initialValue).map((event) {
      final text = event.text.substring(0, max(event.selection.baseOffset, 0));
      return mentionRegExp.firstMatch(text)?[1];
    }).asBroadcastStream();

    addSubscription(
      mentionTextStream.distinct().listen((index) {
        if (!scrollController.hasClients) return;
        scrollController.jumpTo(0);
      }),
    );

    addSubscription(
      Rx.combineLatest2<String?, List<User>, MentionState>(
        mentionTextStream,
        participantsCubit.stream,
        (a, b) {
          late List<User> users;
          if (a == null) {
            users = [];
          } else {
            final keyword = a.toLowerCase();
            users = participantsCubit.state
                .where(
                  (user) =>
                      (user.fullName?.toLowerCase().contains(keyword) ??
                          false) ||
                      user.identityNumber.contains(a),
                )
                .toList()
                  ..sort(compareValuesBy((e) {
                    final indexOf =
                        e.fullName?.toLowerCase().indexOf(keyword) ?? -1;
                    if (indexOf != -1) return indexOf;
                    return e.identityNumber.indexOf(a);
                  }));
          }

          return MentionState(
            text: a,
            users: users,
            index: listEquals(users.map(_mapper).toList(),
                    state.users.map(_mapper).toList())
                ? state.index
                : 0,
          );
        },
      ).listen(emit),
    );
  }

  String _mapper(User e) => e.userId;

  void _jumpToPosition(int index) {
    if (!scrollController.hasClients) return;

    final viewportDimension = scrollController.position.viewportDimension;
    final offset = scrollController.offset;

    final maxScrollExtent = state.users.length * kMentionItemHeight;
    final maxValidScrollExtent = maxScrollExtent - viewportDimension;

    final startIndex = offset ~/ kMentionItemHeight;
    final endIndex =
        (offset + viewportDimension - kMentionItemHeight) ~/ kMentionItemHeight;

    if (index <= startIndex) {
      final pixel = (kMentionItemHeight * index -
              viewportDimension +
              kMentionItemHeight * 2)
          .clamp(0, maxValidScrollExtent)
          .toDouble();
      scrollController.animateTo(pixel,
          duration: const Duration(milliseconds: 150), curve: Curves.easeIn);
    } else if (index >= endIndex) {
      final pixel = (kMentionItemHeight * index - kMentionItemHeight)
          .clamp(0, maxValidScrollExtent)
          .toDouble();
      scrollController.animateTo(pixel,
          duration: const Duration(milliseconds: 150), curve: Curves.easeIn);
    }
  }

  final UserDao userDao;
  final MultiAuthCubit multiAuthCubit;
  final ParticipantsCubit participantsCubit;
  final scrollController = ScrollController();

  @override
  Future<void> close() async {
    scrollController.dispose();
    await super.close();
  }

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
