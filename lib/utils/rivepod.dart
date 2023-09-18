import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract class DistinctStateNotifier<T> extends StateNotifier<T> {
  DistinctStateNotifier(super.state);

  @override
  bool updateShouldNotify(T old, T current) =>
      !identical(old, current) || old != current;
}
