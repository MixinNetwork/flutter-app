import 'package:bloc/bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

T useMemoizedFuture<T>(
  Future<T> Function() futureBuilder,
  T initialData, {
  List<Object?> keys = const <Object>[],
}) =>
    useFuture(
      useMemoized(
        futureBuilder,
        keys,
      ),
      initialData: initialData,
    ).data as T;

T useBloc<T extends Bloc>(
  T Function() valueBuilder, {
  List<Object?> keys = const <Object>[],
}) {
  final sink = useMemoized(valueBuilder, keys);
  useEffect(() => sink.close, keys);
  return sink;
}

S useBlocState<B extends Bloc<dynamic, S>, S>({
  B? bloc,
  List<Object?> keys = const <Object>[],
  bool preserveState = false,
}) {
  final _bloc = useMemoized(
    () => bloc ?? useContext().read<B>(),
    [bloc ?? useContext().read<B>(), ...keys],
  );
  return useStream(_bloc,
          initialData: _bloc.state, preserveState: preserveState)
      .data as S;
}
