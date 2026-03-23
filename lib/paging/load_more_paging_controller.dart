import 'dart:async';

import 'package:equatable/equatable.dart';

class LoadMorePagingState<T> extends Equatable {
  const LoadMorePagingState({this.list = const []});

  final List<T> list;

  @override
  List<Object?> get props => [list];

  LoadMorePagingState<T> copyWith({List<T>? list}) =>
      LoadMorePagingState<T>(list: list ?? this.list);
}

class LoadMorePagingController<T> {
  LoadMorePagingController({
    required this.reloadData,
    required this.loadMoreData,
    required this.isSameKey,
  }) : _state = LoadMorePagingState<T>() {
    unawaited(reload());
  }

  final Future<List<T>> Function() reloadData;
  final Future<List<T>> Function(List<T>) loadMoreData;
  final bool Function(T, T) isSameKey;
  final StreamController<LoadMorePagingState<T>> _stateController =
      StreamController<LoadMorePagingState<T>>.broadcast();
  LoadMorePagingState<T> _state;

  LoadMorePagingState<T> get state => _state;

  Stream<LoadMorePagingState<T>> get stream => _stateController.stream;

  set state(LoadMorePagingState<T> value) {
    if (_state == value) return;
    _state = value;
    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }

  Future<void> reload() async {
    state = LoadMorePagingState<T>(list: await reloadData());
  }

  Future<void> loadMore() async {
    state = state.copyWith(list: await loadMoreData(state.list));
  }

  void insertOrReplace(T item) {
    if (state.list.isEmpty) return;

    final index = state.list.indexWhere((element) => isSameKey(element, item));
    List<T> list;
    if (index == -1) {
      list = [item, ...state.list];
    } else {
      list = state.list.toList();
      list[index] = item;
    }
    state = state.copyWith(list: list);
  }

  void dispose() {
    unawaited(_stateController.close());
  }
}
