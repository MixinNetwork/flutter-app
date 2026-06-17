import 'package:flutter_app/bloc/paging/paging_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  test(
    'initial load derives hasData from count',
    () async {
      final bloc = _TrackingPagingBloc(
        count: 3,
        range: const [1, 2],
      );
      addTearDown(bloc.close);

      final state = await bloc.stream.firstWhere((state) => state.initialized);

      expect(state.hasData, true);
      expect(state.count, 3);
      expect(state.map.values, [1, 2]);
      expect(bloc.queryCountCalls, 1);
      expect(bloc.queryRangeCalls, 1);
    },
  );
}

class _TrackingPagingBloc extends PagingBloc<int> {
  _TrackingPagingBloc({
    required this.count,
    required this.range,
  }) : super(
         initState: const PagingState<int>(),
         itemPositionsListener: ItemPositionsListener.create(),
         limit: 2,
       );

  final int count;
  final List<int> range;
  int queryCountCalls = 0;
  int queryRangeCalls = 0;

  @override
  Future<int> queryCount() async {
    queryCountCalls++;
    return count;
  }

  @override
  Future<List<int>> queryRange(int limit, int offset) async {
    queryRangeCalls++;
    return range;
  }
}
