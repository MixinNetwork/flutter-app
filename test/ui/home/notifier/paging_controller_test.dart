import 'dart:async';

import 'package:flutter_app/ui/home/notifier/paging_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  test('initial load derives hasData from count', () async {
    var queryCountCalls = 0;
    var queryRangeCalls = 0;

    final controller = PagingController<int>(
      itemPositionsListener: ItemPositionsListener.create(),
      limit: 2,
      queryCount: () async {
        queryCountCalls++;
        return 3;
      },
      queryRange: (limit, offset) async {
        queryRangeCalls++;
        return const [1, 2];
      },
    );
    addTearDown(controller.dispose);

    final state = await waitForPagingState(
      controller,
      (state) => state.initialized,
    );

    expect(state.hasData, true);
    expect(state.count, 3);
    expect(state.map.values, [1, 2]);
    expect(queryCountCalls, 1);
    expect(queryRangeCalls, 1);
  });
}

Future<PagingState<T>> waitForPagingState<T>(
  PagingController<T> controller,
  bool Function(PagingState<T>) test,
) {
  final current = controller.value;
  if (test(current)) return Future.value(current);

  final completer = Completer<PagingState<T>>();
  void listener() {
    final state = controller.value;
    if (!test(state)) return;
    controller.removeListener(listener);
    completer.complete(state);
  }

  controller.addListener(listener);
  return completer.future;
}
