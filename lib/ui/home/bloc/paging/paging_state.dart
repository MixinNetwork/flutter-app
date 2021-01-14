part of 'paging_bloc.dart';

class PagingState<T> extends Equatable {
  const PagingState({
    this.list,
    this.noMoreData = false,
  });

  final List<T> list;
  final bool noMoreData;

  @override
  List<Object> get props => [
        list,
        noMoreData,
      ];

  PagingState<T> copyWith({
    List<T> list,
    bool noMoreData,
  }) {
    return PagingState<T>(
      list: list ?? this.list,
      noMoreData: noMoreData ?? this.noMoreData,
    );
  }
}
