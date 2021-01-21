part of 'paging_bloc.dart';

abstract class PagingEvent<T> extends Equatable {
  const PagingEvent();

  @override
  List<Object> get props => [];
}

class _BeforePagingEvent<T> extends PagingEvent<T> {
  const _BeforePagingEvent(this.list);

  final List<T> list;

  @override
  List<Object> get props => [list];
}

class AfterPagingEvent<T> extends PagingEvent<T> {
  const AfterPagingEvent(this.list);

  final List<T> list;

  @override
  List<Object> get props => [list];
}

class ReplacePagingEvent<T> extends PagingEvent<T> {
  const ReplacePagingEvent(this.list);

  final List<T> list;

  @override
  List<Object> get props => [list];
}

class InsertOrUpdatePagingEvent<T> extends PagingEvent<T> {
  const InsertOrUpdatePagingEvent(this.item);

  final T item;

  @override
  List<Object> get props => [item];
}

class RemovePagingEvent<T> extends PagingEvent<T> {
  const RemovePagingEvent(this.item);

  final T item;

  @override
  List<Object> get props => [item];
}
