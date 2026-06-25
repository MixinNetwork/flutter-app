import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/logger.dart';

class LoadMorePagingState<T> extends Equatable {
  const LoadMorePagingState({this.list = const []});

  final List<T> list;

  @override
  List<Object?> get props => [list];

  LoadMorePagingState<T> copyWith({List<T>? list}) =>
      LoadMorePagingState<T>(list: list ?? this.list);
}

class LoadMorePagingController<T>
    extends ValueNotifier<LoadMorePagingState<T>> {
  LoadMorePagingController({
    required this.reloadData,
    required this.loadMoreData,
    required this.isSameKey,
  }) : super(LoadMorePagingState<T>()) {
    _reload();
  }

  final Future<List<T>> Function() reloadData;
  final Future<List<T>> Function(List<T>) loadMoreData;
  final bool Function(T, T) isSameKey;

  var _disposed = false;
  var _isReloading = false;
  var _isLoadingMore = false;

  void _setState(LoadMorePagingState<T> state) {
    if (_disposed) {
      i('load more paging controller: disposed, ignore');
      return;
    }
    value = state;
  }

  Future<void> _reload() async {
    if (_isReloading) return;
    _isReloading = true;
    try {
      _setState(LoadMorePagingState<T>(list: await reloadData()));
    } finally {
      _isReloading = false;
    }
  }

  void loadMore() {
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isReloading || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      _setState(value.copyWith(list: await loadMoreData(value.list)));
    } finally {
      _isLoadingMore = false;
    }
  }

  void insertOrReplace(T item) {
    if (value.list.isEmpty) return;
    final index = value.list.indexWhere((element) => isSameKey(element, item));
    List<T> list;
    if (index == -1) {
      list = [item, ...value.list];
    } else {
      list = value.list.toList();
      list[index] = item;
    }
    _setState(value.copyWith(list: list));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
