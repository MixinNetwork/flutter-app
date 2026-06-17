import 'dart:async';

import 'package:flutter_app/bloc/paging/load_more_paging_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadMore ignores duplicate requests while one is in flight', () async {
    final loadStarted = Completer<void>();
    final completeLoad = Completer<List<int>>();
    var loadMoreCallCount = 0;

    final bloc = LoadMorePagingBloc<int>(
      reloadData: () async => [1],
      loadMoreData: (list) {
        loadMoreCallCount += 1;
        if (!loadStarted.isCompleted) {
          loadStarted.complete();
        }
        return completeLoad.future;
      },
      isSameKey: (a, b) => a == b,
    );
    addTearDown(bloc.close);

    await bloc.stream.firstWhere((state) => state.list.length == 1);

    bloc
      ..loadMore()
      ..loadMore();

    await loadStarted.future;
    await Future<void>.delayed(Duration.zero);

    expect(loadMoreCallCount, 1);

    completeLoad.complete([1, 2]);
    final loaded = await bloc.stream.firstWhere(
      (state) => state.list.length == 2,
    );

    expect(loaded.list, [1, 2]);
  });
}
