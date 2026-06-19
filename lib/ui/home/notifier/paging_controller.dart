import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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

class PagingController<T> extends ValueNotifier<PagingState<T>> {
  PagingController({
    required this.itemPositionsListener,
    required this.limit,
    required this.queryCount,
    required this.queryRange,
    this.jumpTo,
    int offset = 0,
    int index = 0,
    double alignment = 0,
  }) : super(PagingState<T>()) {
    itemPositionsListener.itemPositions.addListener(_onItemPositions);
    init(offset: offset, index: index, alignment: alignment);
  }

  final ItemPositionsListener itemPositionsListener;
  final void Function({int index, double alignment})? jumpTo;
  final Future<int> Function() queryCount;
  final Future<List<T>> Function(int limit, int offset) queryRange;

  int limit;
  List<int> lastItemPositions = [];
  var _generation = 0;
  var _disposed = false;

  void init({int offset = 0, int index = 0, double alignment = 0}) {
    final generation = ++_generation;
    unawaited(_init(generation, offset, index, alignment));
  }

  void update() {
    final generation = ++_generation;
    unawaited(_update(generation));
  }

  void _onItemPositions() {
    final list = itemPositionsListener.itemPositions.value
        .map((e) => e.index)
        .toList();
    if (list.isEmpty) return;

    lastItemPositions = list;
    final generation = ++_generation;
    unawaited(_loadAround(generation, list));
  }

  @override
  void dispose() {
    _disposed = true;
    itemPositionsListener.itemPositions.removeListener(_onItemPositions);
    super.dispose();
  }

  Future<void> _update(int generation) async {
    final count = await queryCount();
    _setState(
      value.copyWith(
        count: count,
        hasData: count != 0,
        map: count == 0 ? {} : value.map,
      ),
      generation,
    );

    if (count == 0) return;
    _setState(
      value.copyWith(
        map: await queryMap(
          max(value.map.length, limit),
          value.map.isNotEmpty ? value.map.keys.reduce(min) : 0,
        ),
        initialized: true,
      ),
      generation,
    );
  }

  Future<void> _loadAround(int generation, List<int> itemPositions) async {
    final prefetchDistance = limit ~/ 2;
    if (!value.initialized ||
        value.map.isEmpty ||
        expectMinListRange(
          itemPositions.first - prefetchDistance,
          itemPositions.last + prefetchDistance,
        )) {
      return;
    }

    final expectStart = itemPositions.first - limit;
    final expectEnd = itemPositions.last + limit;
    final result = differenceMaxExpectRange(expectStart, expectEnd);

    var map = value.map;
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

    _setState(value.copyWith(map: map, initialized: true), generation);
  }

  Future<void> _init(
    int generation,
    int offset,
    int index,
    double alignment,
  ) async {
    final count = await queryCount();
    _setState(
      value.copyWith(
        map: await queryMap(limit, offset),
        count: count,
        hasData: count != 0,
        initialized: true,
        index: index,
        alignment: alignment,
      ),
      generation,
    );

    jumpTo?.call(index: index, alignment: alignment);
  }

  Future<Map<int, T>> queryMap(int limit, int offset) async {
    final safeOffset = max(offset, 0);
    final list = await queryRange(limit, safeOffset);
    return Map.fromIterables(
      List.generate(min(limit, list.length), (index) => safeOffset + index),
      list,
    );
  }

  bool expectMinListRange(int start, int end) {
    final safeStart = max(start, 0);
    final safeEnd = max(min(end, value.count - 1), 0);
    return value.map[safeStart] != null && value.map[safeEnd] != null;
  }

  List<(int, int)> differenceMaxExpectRange(int start, int end) {
    final safeStart = max(start, 0);
    final safeEnd = min(end, value.count);
    final loadedIndexes = value.map.keys.toList();

    (int, int)? before;
    (int, int)? after;

    if (safeStart < loadedIndexes.first) {
      before = (safeStart, min(loadedIndexes.first, safeEnd));
    }

    if (loadedIndexes.last < safeEnd) {
      after = (max(loadedIndexes.last, safeStart), safeEnd);
    }

    return [?before, ?after];
  }

  void _setState(PagingState<T> state, int generation) {
    if (_disposed || generation != _generation) return;
    value = state;
  }
}
