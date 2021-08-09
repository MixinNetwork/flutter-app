import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

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

AsyncSnapshot<T> useMemoizedStream<T>(
  Stream<T> Function() valueBuilder, {
  T? initialData,
  List<Object?> keys = const <Object>[],
}) =>
    useStream<T>(
      useMemoized<Stream<T>>(valueBuilder, keys),
      initialData: initialData,
    );

T useBloc<T extends BlocBase>(
  T Function() valueBuilder, {
  List<Object?> keys = const <Object>[],
}) {
  final sink = useMemoized(valueBuilder, keys);
  useEffect(() => sink.close, keys);
  return sink;
}

S useBlocState<B extends BlocBase<S>, S>({
  B? bloc,
  List<Object?> keys = const <Object>[],
  bool preserveState = false,
  bool Function(S state)? when,
}) {
  final tuple = useMemoized(
    () {
      final b = bloc ?? useContext().read<B>();
      var stream = b.stream;
      if (when != null) stream = stream.where(when);
      return Tuple2(stream.distinct(), b.state);
    },
    [bloc ?? useContext().read<B>(), ...keys],
  );
  return useStream(
    tuple.item1,
    initialData: tuple.item2,
    preserveState: preserveState,
  ).data as S;
}

T useBlocStateConverter<B extends BlocBase<S>, S, T>({
  B? bloc,
  List<Object?> keys = const <Object>[],
  bool preserveState = false,
  bool Function(T)? when,
  required T Function(S) converter,
}) {
  final tuple = useMemoized(
    () {
      final b = bloc ?? useContext().read<B>();
      var stream = b.stream.map(converter);
      if (when != null) stream = stream.where(when);
      return Tuple2(stream.distinct(), converter(b.state));
    },
    [bloc ?? useContext().read<B>(), ...keys],
  );
  return useStream(
    tuple.item1,
    initialData: tuple.item2,
    preserveState: preserveState,
  ).data as T;
}

Stream<T> useValueNotifierConvertSteam<T>(ValueNotifier<T> valueNotifier) {
  final streamController = useStreamController<T>(keys: [valueNotifier]);
  useEffect(() {
    void onListen() => streamController.add(valueNotifier.value);

    valueNotifier.addListener(onListen);
    return () {
      valueNotifier.removeListener(onListen);
    };
  }, [valueNotifier]);

  final stream = useMemoized(() => streamController.stream, [valueNotifier]);
  return stream;
}

AsyncSnapshot<T> useListenableConverter<L extends Listenable, T>(
  L listenable, {
  required T Function(L) converter,
  List<Object?> keys = const <Object>[],
  T? initialData,
}) {
  final streamController = useStreamController<T>(
    keys: [listenable, ...keys],
  );

  useEffect(
    () {
      void onListen() => streamController.add(converter(listenable));

      listenable.addListener(onListen);
      return () {
        listenable.removeListener(onListen);
      };
    },
    [listenable, ...keys],
  );

  final stream = useMemoized(
    () => streamController.stream.distinct(),
    [listenable, ...keys],
  );
  return useStream(stream, initialData: initialData);
}
