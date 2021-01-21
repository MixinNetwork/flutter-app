import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/bloc/subscribe_mixin.dart';
import 'package:flutter_app/utils/multi_field_compare.dart';
import 'package:flutter_app/utils/stream_extension.dart';

part 'paging_event.dart';
part 'paging_state.dart';

abstract class PagingBloc<T, S extends PagingState<T>>
    extends Bloc<PagingEvent<T>, S> with SubscribeMixin {
  PagingBloc(S s) : super(s) {
    setup();
  }

  StreamController<List<T>> loadMoreStreamController;

  List<MultiFieldCompareParameter<T>> get parameters;

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

    if (event is _BeforePagingEvent<T>) {
      yield state.copyWith(
        list: list + event.list,
        noMoreData: event.list?.isEmpty ?? true,
      );

      return;
    }

    if (event is InsertOrUpdatePagingEvent<T>) {
      final index = list.indexWhere((e) => test(e, event.item));
      if (index >= 0) {
        list[index] = event.item;
      } else {
        list.insert(0, event.item);
      }
      yield state.copyWith(list: list..sort(multiFieldCompare(parameters)));
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
    loadMoreStreamController?.close();
    loadMoreStreamController = StreamController<List<T>>();
    loadMoreStreamController.stream
        .asyncMapDrop(before)
        .handleError((_) => null)
        .listen(
      (list) {
        if (list == null) return;
        add(_BeforePagingEvent(list));
      },
    );
    firstLoad();
  }

  @protected
  void firstLoad();

  @protected
  Future<List<T>> before(List<T> list);

  void loadBefore() {
    if (state.noMoreData || state.list.isEmpty ?? true) return;
    loadMoreStreamController.add(state.list);
  }
}
