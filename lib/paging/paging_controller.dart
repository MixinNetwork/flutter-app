import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PagingState<T> extends Equatable {
  const PagingState({
    this.map = const {},
    this.count = 0,
    this.initialized = false,
    this.index = 0,
    this.alignment = 0,
    this.hasData = false,
  });

  final Map<int, T> map;
  final int count;
  final bool initialized;
  final int index;
  final double alignment;
  final bool hasData;

  @override
  List<Object> get props => [
    map,
    count,
    initialized,
    index,
    alignment,
    hasData,
  ];

  PagingState<T> copyWith({
    Map<int, T>? map,
    int? count,
    bool? initialized,
    int? index,
    double? alignment,
    bool? hasData,
  }) => PagingState(
    map: map ?? this.map,
    count: count ?? this.count,
    initialized: initialized ?? this.initialized,
    index: index ?? this.index,
    alignment: alignment ?? this.alignment,
    hasData: hasData ?? this.hasData,
  );

  @override
  bool get stringify => true;
}

abstract class PagingController<T> {
  PagingController({
    required this.itemPositionsListener,
    required this.limit,
    required PagingState<T> initState,
    this.jumpTo,
    int offset = 0,
    int index = 0,
    double alignment = 0,
  }) : _state = initState {
    itemPositionsListener.itemPositions.addListener(_onItemPositions);
    unawaited(
      initialize(offset: offset, index: index, alignment: alignment),
    );
  }

  final ItemPositionsListener itemPositionsListener;
  final void Function({int index, double alignment})? jumpTo;
  final StreamController<PagingState<T>> _stateController =
      StreamController<PagingState<T>>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PagingState<T> _state;

  int limit;
  List<int> lastItemPositions = [];

  PagingState<T> get state => _state;

  Stream<PagingState<T>> get stream => _stateController.stream;

  set state(PagingState<T> value) {
    if (_state == value) return;
    _state = value;
    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }

  void addSubscription(StreamSubscription<dynamic> subscription) {
    _subscriptions.add(subscription);
  }

  void _onItemPositions() {
    final list = itemPositionsListener.itemPositions.value
        .map((e) => e.index)
        .toList();
    if (list.isEmpty) return;

    unawaited(handleItemPositions(list));
  }

  Future<void> initialize({
    int offset = 0,
    int index = 0,
    double alignment = 0,
  }) async {
    state = state.copyWith(hasData: await queryHasData());

    final count = await queryCount();

    state = state.copyWith(
      map: await queryMap(limit, offset),
      count: count,
      initialized: true,
      index: index,
      alignment: alignment,
    );

    jumpTo?.call(index: index, alignment: alignment);
  }

  Future<void> refresh() async {
    final count = await queryCount();
    state = state.copyWith(
      count: count,
      hasData: count != 0,
      map: count == 0 ? {} : state.map,
    );

    if (count != 0) {
      state = state.copyWith(
        map: await queryMap(
          max(state.map.length, limit),
          state.map.isNotEmpty ? state.map.keys.reduce(min) : 0,
        ),
        initialized: true,
      );
    }
  }

  Future<void> handleItemPositions(List<int> itemPositions) async {
    lastItemPositions = itemPositions;
    final prefetchDistance = limit ~/ 2;

    if (!state.initialized ||
        state.map.isEmpty ||
        expectMinListRange(
          itemPositions.first - prefetchDistance,
          itemPositions.last + prefetchDistance,
        )) {
      return;
    }

    final expectStart = itemPositions.first - limit;
    final expectEnd = itemPositions.last + limit;
    final result = differenceMaxExpectRange(expectStart, expectEnd);

    var map = state.map;
    if (result.length > 1 && (result.first.$2 - result.first.$1) > limit) {
      map = await queryMap(
        itemPositions.length + limit,
        itemPositions.first - prefetchDistance,
      );
    } else {
      for (final (start, end) in result) {
        map = {...map, ...await queryMap(end - start, start)};
      }

      if (map.length > expectEnd - expectStart) {
        map.removeWhere((key, value) => key < expectStart || key > expectEnd);
      }
    }

    state = state.copyWith(map: map, initialized: true);
  }

  Future<Map<int, T>> queryMap(int limit, int _offset) async {
    final offset = max(_offset, 0);
    final list = await queryRange(limit, offset);
    return Map.fromIterables(
      List.generate(min(limit, list.length), (index) => offset + index),
      list,
    );
  }

  bool expectMinListRange(int _start, int _end) {
    final start = max(_start, 0);
    final end = max(min(_end, state.count - 1), 0);
    return state.map[start] != null && state.map[end] != null;
  }

  List<(int, int)> differenceMaxExpectRange(int _start, int _end) {
    final start = max(_start, 0);
    final end = min(_end, state.count);
    final loadedIndexes = state.map.keys.toList();

    (int, int)? before;
    (int, int)? after;

    if (start < loadedIndexes.first) {
      before = (start, min(loadedIndexes.first, end));
    }

    if (loadedIndexes.last < end) {
      after = (max(loadedIndexes.last, start), end);
    }

    return [before, after].nonNulls.toList();
  }

  Future<int> queryCount();

  Future<List<T>> queryRange(int limit, int offset);

  Future<bool> queryHasData();

  void dispose() {
    itemPositionsListener.itemPositions.removeListener(_onItemPositions);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    unawaited(_stateController.close());
  }
}

class AnonymousPagingController<T> extends PagingController<T> {
  AnonymousPagingController({
    required super.itemPositionsListener,
    required super.limit,
    required super.jumpTo,
    required Future<int> Function() queryCount,
    required Future<List<T>> Function(int limit, int offset) queryRange,
    required Future<bool> Function() queryHasData,
    super.offset,
    super.index,
    super.alignment,
  }) : _queryCount = queryCount,
       _queryRange = queryRange,
       _queryHasData = queryHasData,
       super(
         initState: PagingState<T>(),
       );

  final Future<int> Function() _queryCount;
  final Future<List<T>> Function(int limit, int offset) _queryRange;
  final Future<bool> Function() _queryHasData;

  @override
  Future<int> queryCount() => _queryCount();

  @override
  Future<List<T>> queryRange(int limit, int offset) =>
      _queryRange(limit, offset);

  @override
  Future<bool> queryHasData() => _queryHasData();
}
