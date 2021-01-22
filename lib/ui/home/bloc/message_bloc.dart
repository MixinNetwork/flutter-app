import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuple/tuple.dart';

import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/conversation_cubit.dart';

class MessageState extends Equatable {
  const MessageState({
    this.map = const {},
    this.count,
    this.initialized = false,
    this.index = 0,
    this.alignment = 0,
  });
  final Map<int, MessageItem> map;
  final int count;
  final bool initialized;
  final int index;
  final double alignment;

  @override
  List<Object> get props => [
        map,
        count,
        initialized,
        index,
        alignment,
      ];

  MessageState copyWith({
    Map<int, MessageItem> map,
    int count,
    bool initialized,
    int index,
    double alignment,
  }) {
    return MessageState(
      map: map ?? this.map,
      count: count ?? this.count,
      initialized: initialized ?? this.initialized,
      index: index ?? this.index,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  final stringify = true;
}

abstract class _MessageEvent extends Equatable {}

class _MessageInitEvent extends _MessageEvent {
  _MessageInitEvent({
    this.offset = 0,
    this.index = 0,
    this.alignment = 0,
  });

  final int offset;
  final int index;
  final double alignment;

  @override
  List<Object> get props => [
        offset,
        index,
        alignment,
      ];
}

class _MessageItemPositionEvent extends _MessageEvent {
  _MessageItemPositionEvent(this.itemPositions);
  final List<int> itemPositions;

  @override
  List<Object> get props => [itemPositions];
}

class MessageBloc extends Bloc<_MessageEvent, MessageState>
    with SubscribeMixin {
  MessageBloc({
    this.itemPositions,
    this.messagesDao,
    this.conversationCubit,
    this.limit,
    this.jumpTo,
    int offset,
    int index,
    double alignment,
  })  : conversationId = conversationCubit.state.conversationId,
        super(const MessageState()) {
    itemPositions.addListener(onItemPositions);
    add(_MessageInitEvent(
      offset: offset,
      index: index,
      alignment: alignment,
    ));
    addSubscription(conversationCubit.listen((state) {
      conversationId = state.conversationId;
      add(_MessageInitEvent(
        offset: offset,
        index: index,
        alignment: alignment,
      ));
    }));
  }

  final ConversationCubit conversationCubit;
  final MessagesDao messagesDao;
  final ValueListenable<Iterable<ItemPosition>> itemPositions;
  final void Function({int index, double alignment}) jumpTo;

  String conversationId;
  int limit;

  void onItemPositions() {
    add(_MessageItemPositionEvent(
        itemPositions.value.map((e) => e.index).toList()));
  }

  @override
  Future<void> close() async {
    itemPositions.removeListener(onItemPositions);
    await super.close();
  }

  @override
  Stream<Transition<_MessageEvent, MessageState>> transformEvents(
    Stream<_MessageEvent> events,
    TransitionFunction<_MessageEvent, MessageState> transitionFn,
  ) {
    final nonDebounceStream =
        events.where((event) => event is! _MessageItemPositionEvent);
    final debounceStream = events
        .where((event) => event is _MessageItemPositionEvent)
        .distinct()
        .debounceTime(const Duration(milliseconds: 5));

    return super.transformEvents(
        Rx.merge([nonDebounceStream, debounceStream]), transitionFn);
  }

  @override
  Stream<MessageState> mapEventToState(_MessageEvent event) async* {
    final prefetchDistance = limit ~/ 2;

    if (event is _MessageItemPositionEvent) {
      if (!state.initialized ||
          state.map.isEmpty ||
          expectMinListRange(event.itemPositions.first - prefetchDistance,
              event.itemPositions.last + prefetchDistance)) return;

      final expectStart = event.itemPositions.first - limit;
      final expectEnd = event.itemPositions.last + limit;

      final result = differenceMaxExpectRange(expectStart, expectEnd);

      var map = state.map;
      for (final tuple in result) {
        map = {
          ...map,
          ...await queryMap(tuple.item2 - tuple.item1, tuple.item1)
        };
      }

      if (map.length > expectEnd - expectStart)
        map.removeWhere((key, value) => key < expectStart || key > expectEnd);

      yield state.copyWith(
        map: map,
      );
    } else if (event is _MessageInitEvent) {
      final offset = event.offset;

      final count = await messagesDao
          .messageCountByConversationId(conversationId)
          .getSingle();

      yield state.copyWith(
        map: await queryMap(limit, offset),
        count: count,
        initialized: true,
        index: event.index,
        alignment: event.alignment,
      );

      jumpTo?.call(
        index: event.index,
        alignment: event.alignment,
      );
    }
  }

  Future<Map<int, MessageItem>> queryMap(int limit, int offset) async {
    final list = await messagesDao
        .messagesByConversationId(conversationId, limit, offset: offset)
        .get();
    final map = Map.fromIterables(
      List.generate(limit, (index) => offset + index),
      list,
    );
    return map;
  }

  bool expectMinListRange(int _start, int _end) {
    final start = max(_start, 0);
    final end = max(min(_end, state.count - 1), 0);
    return state.map[start] != null && state.map[end] != null;
  }

  List<Tuple2<int, int>> differenceMaxExpectRange(int _start, int _end) {
    final start = max(_start, 0);
    final end = min(_end, state.count - 1);
    final loadedindexes = state.map.keys.toList();

    Tuple2<int, int> before;
    Tuple2<int, int> after;

    if (start < loadedindexes.first)
      before = Tuple2(start, min(loadedindexes.first, end));

    if (loadedindexes.last < end)
      after = Tuple2(max(loadedindexes.last, start), end);

    return [
      if (before != null) before,
      if (after != null) after,
    ];
  }
}
