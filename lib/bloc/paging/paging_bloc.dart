import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';

part 'paging_event.dart';
part 'paging_state.dart';

abstract class PagingBloc<T, S extends PagingState<T>>
    extends Bloc<PagingEvent<T>, S> with SubscribeMixin {
  PagingBloc(S s) : super(s) {
    setup();
  }

  StreamController<List<T>> loadMoreStreamController;

  @override
  Stream<S> mapEventToState(PagingEvent<T> event) async* {
    final list = state.list?.toList() ?? [];

    if (event is ReplacePagingEvent<T>) {
      yield state.copyWith(
        noMoreData: false,
        list: event.list,
      );
      return;
    }

    if (event is BeforePagingEvent<T>) {
      yield state.copyWith(
        list: list + event.list,
        noMoreData: event.list?.isEmpty ?? true,
      );
      return;
    }

    if (event is InsertOrReplacePagingEvent<T>) {
      final index = list.indexWhere((e) => test(e, event.item));
      if (index >= 0) {
        list[index] = event.item;
      } else {
        list.insert(0, event.item);
      }
      yield state.copyWith(list: list);
      return;
    }

    if (event is InsertOrMovePagingEvent<T>) {
      final index = list.indexWhere((e) => test(e, event.item));
      if (index >= 0) list.removeAt(index);
      list.insert(0, event.item);
      yield state.copyWith(list: list);
      return;
    }
  }

  @override
  Future<void> close() {
    loadMoreStreamController?.close();
    return super.close();
  }

  bool test(T a, T b);

  @protected
  @mustCallSuper
  void setup() {
    firstLoad();
  }

  @protected
  void firstLoad();

  @protected
  Future<List<T>> before(List<T> list);

  void loadBefore() {
    if (loadMoreStreamController != null ||
            state.noMoreData ||
            state.list.isEmpty ??
        true) return;

    loadMoreStreamController = StreamController<List<T>>(sync: true);
    addSubscription(
      loadMoreStreamController.stream
          .asyncMap(before)
          .handleError((_) => null)
          .listen(
        (list) {
          loadMoreStreamController.close();
          loadMoreStreamController = null;

          if (list == null) return;
          add(BeforePagingEvent(list));
        },
      ),
    );
    loadMoreStreamController.add(state.list);
  }
}
