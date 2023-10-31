import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../db/dao/user_dao.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../../utils/extension/extension.dart';
import '../../utils/reg_exp_utils.dart';
import '../../utils/rivepod.dart';
import '../../widgets/mention_panel.dart';
import '../home/bloc/subscriber_mixin.dart';
import 'account/multi_auth_provider.dart';
import 'conversation_provider.dart';
import 'database_provider.dart';

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

class MentionStateNotifier extends DistinctStateNotifier<MentionState>
    with SubscriberMixin {
  MentionStateNotifier({
    required this.userDao,
    required this.multiAuthChangeNotifier,
    required this.textEditingValueStream,
    required String conversationId,
    required bool? isGroup,
    required bool? isBot,
  }) : super(const MentionState()) {
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
        if (isBot ?? false) {
          return userDao.friends().watchWithStream(
            eventStreams: [DataBaseEventBus.instance.updateUserIdsStream],
            duration: kVerySlowThrottleDuration,
          ).map((value) => _resultToMentionState(keyword, value));
        }
        if (isGroup ?? false) {
          return userDao.groupParticipants(conversationId).watchWithStream(
            eventStreams: [
              DataBaseEventBus.instance.watchUpdateParticipantStream(
                  conversationIds: [conversationId])
            ],
            duration: kVerySlowThrottleDuration,
          ).map((value) => _resultToMentionState(
              keyword,
              value
                ..removeWhere(
                  (element) =>
                      element.userId == multiAuthChangeNotifier.current!.userId,
                )));
        }
      }

      if (isBot ?? false) {
        return userDao
            .fuzzySearchBotGroupUser(
          currentUserId: multiAuthChangeNotifier.current?.userId ?? '',
          conversationId: conversationId,
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
      if (isGroup ?? false) {
        return userDao
            .fuzzySearchGroupUser(
          multiAuthChangeNotifier.current?.userId ?? '',
          conversationId,
          keyword,
        )
            .watchWithStream(
          eventStreams: [
            DataBaseEventBus.instance
                .watchUpdateParticipantStream(conversationIds: [conversationId])
          ],
          duration: kVerySlowThrottleDuration,
        ).map((value) => _resultToMentionState(keyword, value));
      }
      return Stream.value(MentionState(text: keyword));
    }).listen((value) => state = value));
  }

  MentionStateNotifier.idle({
    required this.userDao,
    required this.multiAuthChangeNotifier,
    required this.textEditingValueStream,
  }) : super(const MentionState());

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
  final MultiAuthStateNotifier multiAuthChangeNotifier;
  final Stream<TextEditingValue> textEditingValueStream;

  final scrollController = ScrollController();

  @override
  Future<void> dispose() async {
    scrollController.dispose();
    super.dispose();
  }

  void next() {
    final index = min(state.index + 1, state.users.length - 1);
    state = state.copyWith(
      index: index,
    );
    _jumpToPosition(index);
  }

  void prev() {
    final index = max(state.index - 1, 0);
    state = state.copyWith(
      index: index,
    );
    _jumpToPosition(index);
  }
}

final mentionProvider = StateNotifierProvider.autoDispose
    .family<MentionStateNotifier, MentionState, Stream<TextEditingValue>>(
  (ref, stream) {
    final userDao = ref
        .watch(databaseProvider.select((value) => value.requireValue.userDao));
    final authStateNotifier =
        ref.watch(multiAuthStateNotifierProvider.notifier);
    final (conversationId, isGroup, isBot) = ref.watch(
        conversationProvider.select(
            (value) => (value?.conversationId, value?.isGroup, value?.isBot)));

    if (conversationId == null) {
      return MentionStateNotifier.idle(
        userDao: userDao,
        multiAuthChangeNotifier: authStateNotifier,
        textEditingValueStream: stream,
      );
    }

    return MentionStateNotifier(
      userDao: userDao,
      multiAuthChangeNotifier: authStateNotifier,
      textEditingValueStream: stream,
      conversationId: conversationId,
      isGroup: isGroup,
      isBot: isBot,
    );
  },
);
