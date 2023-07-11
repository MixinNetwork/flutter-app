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
import '../../../db/database_event_bus.dart';
import '../../../db/mixin_database.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/reg_exp_utils.dart';
import '../../../widgets/mention_panel.dart';
import 'conversation_cubit.dart';
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
    String? text,
    List<User>? users,
    int? index,
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
  }) : super(const MentionState());

  void setTextEditingValueStream(
    Stream<TextEditingValue> textEditingValueStream,
    ConversationState conversationState,
  ) {
    Future.wait(subscriptions
        .toList()
        .where((element) => element != null)
        .map((e) => e!.cancel()));

    final mentionTextStream = textEditingValueStream.map((event) {
      final text = event.text.substring(0, max(event.selection.baseOffset, 0));
      return mentionRegExp.firstMatch(text)?[1];
    }).asBroadcastStream();

    addSubscription(
      mentionTextStream.distinct().listen((index) {
        if (!scrollController.hasClients) return;
        scrollController.jumpTo(0);
      }),
    );

    addSubscription(mentionTextStream.switchMap((keyword) {
      if (keyword == null) {
        return Stream.value(MentionState(text: keyword));
      }
      if (keyword.isEmpty) {
        if (conversationState.isBot ?? false) {
          return userDao.friends().watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateUserIdsStream],
            duration: kVerySlowThrottleDuration,
          ).map((value) => _resultToMentionState(keyword, value));
        }
        if (conversationState.isGroup ?? false) {
          return userDao
              .groupParticipants(conversationState.conversationId)
              .watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateParticipantStream(
                  conversationIds: [conversationState.conversationId])
            ],
            duration: kVerySlowThrottleDuration,
          ).map((value) => _resultToMentionState(
                  keyword,
                  value
                    ..removeWhere(
                      (element) =>
                          element.userId == multiAuthCubit.state.currentUserId,
                    )));
        }
      }

      if (conversationState.isBot ?? false) {
        return userDao
            .fuzzySearchBotGroupUser(
          currentUserId: multiAuthCubit.state.currentUserId ?? '',
          conversationId: conversationState.conversationId,
          keyword: keyword,
        )
            .watchWithStream(
          eventStreams: [
            DataBaseEventBus.instance.updateUserIdsStream,
            DataBaseEventBus.instance.insertOrReplaceMessageIdsStream,
            DataBaseEventBus.instance.deleteMessageIdStream,
          ],
          duration: kVerySlowThrottleDuration,
        ).map((value) => _resultToMentionState(keyword, value));
      }
      if (conversationState.isGroup ?? false) {
        return userDao
            .fuzzySearchGroupUser(
          multiAuthCubit.state.currentUserId ?? '',
          conversationState.conversationId,
          keyword,
        )
            .watchWithStream(
          eventStreams: [
            DataBaseEventBus.instance.watchUpdateParticipantStream(
                conversationIds: [conversationState.conversationId])
          ],
          duration: kVerySlowThrottleDuration,
        ).map((value) => _resultToMentionState(keyword, value));
      }
      return Stream.value(MentionState(text: keyword));
    }).listen(emit));
  }

  MentionState _resultToMentionState(String? keyword, List<User> users) =>
      MentionState(
        text: keyword,
        users: users,
        index: listEquals(
                users.map(_mapper).toList(), state.users.map(_mapper).toList())
            ? state.index
            : 0,
      );

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
