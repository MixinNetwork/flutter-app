import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:tuple/tuple.dart';

import 'package:flutter_app/bloc/subscribe_mixin.dart';

class PagingState<T> extends Equatable {
  const PagingState({
    this.map = const {},
    this.count = 0,
    this.initialized = false,
    this.index = 0,
    this.alignment = 0,
  });

  final Map<int, T> map;
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

  PagingState<T> copyWith({
    Map<int, T>? map,
    int? count,
    bool? initialized,
    int? index,
    double? alignment,
  }) {
    return PagingState(
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

abstract class PagingEvent extends Equatable {}

class PagingInitEvent extends PagingEvent {
  PagingInitEvent({
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

class PagingItemPositionEvent extends PagingEvent {
  PagingItemPositionEvent(this.itemPositions);

  final List<int> itemPositions;

  @override
  List<Object> get props => [itemPositions];
}

class PagingUpdateEvent extends PagingEvent {
  @override
  List<Object> get props => [];
}

abstract class PagingBloc<T> extends Bloc<PagingEvent, PagingState<T>>
    with SubscribeMixin {
  PagingBloc({
    required this.itemPositionsListener,
    required this.limit,
    this.jumpTo,
    int offset = 0,
    int index = 0,
    double alignment = 0,
    required PagingState<T> initState,
  }) : super(initState) {
    itemPositionsListener?.itemPositions.addListener(onItemPositions);
    add(PagingInitEvent(
      offset: offset,
      index: index,
      alignment: alignment,
    ));
  }

  final ItemPositionsListener? itemPositionsListener;
  final void Function({int index, double alignment})? jumpTo;

  int limit;
  List<int> lastItemPositions = [];

  void onItemPositions() {
    final list =
        itemPositionsListener?.itemPositions.value.map((e) => e.index).toList();
    if (list?.isEmpty ?? true) return;

    add(PagingItemPositionEvent(list!));
  }

  @override
  Future<void> close() async {
    itemPositionsListener?.itemPositions.removeListener(onItemPositions);
    await super.close();
  }

  @override
  Stream<Transition<PagingEvent, PagingState<T>>> transformEvents(
      Stream<PagingEvent> events,
      TransitionFunction<PagingEvent, PagingState<T>> transitionFn) {
    final asBroadcastStream = events.asBroadcastStream();
    final nonDebounceStream =
        asBroadcastStream.where((event) => event is! PagingItemPositionEvent);
    final debounceStream = asBroadcastStream
        .where((event) => event is PagingItemPositionEvent)
        .distinct();

    return super.transformEvents(
        Rx.merge([nonDebounceStream, debounceStream]), transitionFn);
  }

  @override
  Stream<PagingState<T>> mapEventToState(PagingEvent event) async* {
    final prefetchDistance = limit ~/ 2;

    if (event is PagingUpdateEvent) {
      yield state.copyWith(
        count: await queryCount(),
      );
      yield state.copyWith(
        map: await queryMap(
          max(state.map.length, limit),
          state.map.isNotEmpty ? state.map.keys.reduce(min) : 0,
        ),
      );
    } else if (event is PagingItemPositionEvent) {
      lastItemPositions = event.itemPositions;
      if (!state.initialized ||
          state.map.isEmpty ||
          expectMinListRange(event.itemPositions.first - prefetchDistance,
              event.itemPositions.last + prefetchDistance)) return;

      final expectStart = event.itemPositions.first - limit;
      final expectEnd = event.itemPositions.last + limit;

      final result = differenceMaxExpectRange(expectStart, expectEnd);

      var map = state.map;
      // If the diff range has only one direction and is greater than the limit
      if (result.length > 1 &&
          (result.first.item2 - result.first.item1) > limit) {
        map = await queryMap(event.itemPositions.length + limit,
            event.itemPositions.first - prefetchDistance);
      } else {
        for (final tuple in result) {
          map = {
            ...map,
            ...await queryMap(tuple.item2 - tuple.item1, tuple.item1)
          };
        }

        if (map.length > expectEnd - expectStart)
          map.removeWhere((key, value) => key < expectStart || key > expectEnd);
      }

      yield state.copyWith(
        map: map,
      );
    } else if (event is PagingInitEvent) {
      final offset = event.offset;

      final count = await queryCount();

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

  Future<Map<int, T>> queryMap(int limit, int _offset) async {
    final offset = max(_offset, 0);
    final list = await queryRange(limit, max(offset, 0));
    final map = Map.fromIterables(
      List.generate(min(limit, list.length), (index) => offset + index),
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
    final end = min(_end, state.count);
    final loadedindexes = state.map.keys.toList();

    Tuple2<int, int>? before;
    Tuple2<int, int>? after;

    if (start < loadedindexes.first)
      before = Tuple2(start, min(loadedindexes.first, end));

    if (loadedindexes.last < end)
      after = Tuple2(max(loadedindexes.last, start), end);

    return [
      if (before != null) before,
      if (after != null) after,
    ];
  }

  Future<int> queryCount();

  Future<List<T>> queryRange(int limit, int offset);
}
