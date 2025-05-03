import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class _LoadMorePagingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class _LoadMorePagingInitEvent extends _LoadMorePagingEvent {}

class _LoadMorePagingLoadMoreEvent extends _LoadMorePagingEvent {}

class _LoadMorePagingInsertOrReplaceEvent<T> extends _LoadMorePagingEvent {
  _LoadMorePagingInsertOrReplaceEvent(this.item);

  final T item;

  @override
  List<Object?> get props => [item];
}

class LoadMorePagingState<T> extends Equatable {
  const LoadMorePagingState({this.list = const []});

  final List<T> list;

  @override
  List<Object?> get props => [list];

  LoadMorePagingState<T> copyWith({List<T>? list}) =>
      LoadMorePagingState<T>(list: list ?? this.list);
}

class LoadMorePagingBloc<T>
    extends Bloc<_LoadMorePagingEvent, LoadMorePagingState<T>> {
  LoadMorePagingBloc({
    required this.reloadData,
    required this.loadMoreData,
    required this.isSameKey,
  }) : super(LoadMorePagingState<T>()) {
    on<_LoadMorePagingEvent>(_onEvent);
    add(_LoadMorePagingInitEvent());
  }

  final Future<List<T>> Function() reloadData;
  final Future<List<T>> Function(List<T>) loadMoreData;
  final bool Function(T, T) isSameKey;

  Future<void> _onEvent(
    _LoadMorePagingEvent event,
    Emitter<LoadMorePagingState<T>> emit,
  ) async {
    if (event is _LoadMorePagingInitEvent) {
      emit(LoadMorePagingState<T>(list: await reloadData()));
    } else if (event is _LoadMorePagingLoadMoreEvent) {
      emit(state.copyWith(list: await loadMoreData(state.list)));
    } else if (event is _LoadMorePagingInsertOrReplaceEvent<T>) {
      if (state.list.isEmpty) return;
      final index = state.list.indexWhere(
        (element) => isSameKey(element, event.item),
      );
      List<T> list;
      if (index == -1) {
        list = [event.item, ...state.list];
      } else {
        list = state.list.toList();
        list[index] = event.item;
      }
      emit(state.copyWith(list: list));
    }
  }

  void loadMore() => add(_LoadMorePagingLoadMoreEvent());

  void insertOrReplace(T item) =>
      add(_LoadMorePagingInsertOrReplaceEvent(item));
}
