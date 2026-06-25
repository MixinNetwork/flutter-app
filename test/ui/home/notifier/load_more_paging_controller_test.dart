import 'dart:async';

import 'package:flutter_app/ui/home/notifier/load_more_paging_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadMore ignores duplicate requests while one is in flight', () async {
    final loadStarted = Completer<void>();
    final completeLoad = Completer<List<int>>();
    var loadMoreCallCount = 0;

    final controller = LoadMorePagingController<int>(
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
    addTearDown(controller.dispose);

    await waitForState(controller, (state) => state.list.length == 1);

    controller
      ..loadMore()
      ..loadMore();

    await loadStarted.future;
    await Future<void>.delayed(Duration.zero);

    expect(loadMoreCallCount, 1);

    completeLoad.complete([1, 2]);
    final loaded = await waitForState(
      controller,
      (state) => state.list.length == 2,
    );

    expect(loaded.list, [1, 2]);
  });
}

Future<LoadMorePagingState<T>> waitForState<T>(
  LoadMorePagingController<T> controller,
  bool Function(LoadMorePagingState<T>) test,
) {
  final current = controller.value;
  if (test(current)) return Future.value(current);

  final completer = Completer<LoadMorePagingState<T>>();
  void listener() {
    final state = controller.value;
    if (!test(state)) return;
    controller.removeListener(listener);
    completer.complete(state);
  }

  controller.addListener(listener);
  return completer.future;
}
