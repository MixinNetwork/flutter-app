import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

AsyncSnapshot<T> useMemoizedFuture<T>(
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
    );

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

  final stream = useMemoized(
      () => streamController.stream.startWith(valueNotifier.value),
      [valueNotifier]);
  return stream;
}

AsyncSnapshot<T> useListenableConverter<L extends Listenable, T>(
  L listenable, {
  required T Function(L) converter,
  List<Object?> keys = const <Object>[],
}) {
  final streamController = useStreamController<T>(
    keys: [listenable, ...keys],
  );

  final initialData = useMemoized(() => converter(listenable));

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

class _RouteCallbacks with RouteAware {
  const _RouteCallbacks({
    this.handleDidPopNext,
    this.handleDidPush,
    this.handleDidPop,
    this.handleDidPushNext,
  });

  final VoidCallback? handleDidPopNext;
  final VoidCallback? handleDidPush;
  final VoidCallback? handleDidPop;
  final VoidCallback? handleDidPushNext;

  @override
  void didPopNext() {
    handleDidPopNext?.call();
  }

  @override
  void didPush() {
    handleDidPush?.call();
  }

  @override
  void didPop() {
    handleDidPop?.call();
  }

  @override
  void didPushNext() {
    handleDidPushNext?.call();
  }
}

void useRouteObserver(
  RouteObserver<ModalRoute> routeObserver, {
  BuildContext? context,
  VoidCallback? didPopNext,
  VoidCallback? didPush,
  VoidCallback? didPop,
  VoidCallback? didPushNext,
  List<Object?> keys = const [],
}) {
  final _context = context ?? useContext();
  final route = ModalRoute.of(_context);

  useEffect(() {
    if (route == null) return () {};

    final callbacks = _RouteCallbacks(
      handleDidPop: didPop,
      handleDidPopNext: didPopNext,
      handleDidPush: didPush,
      handleDidPushNext: didPushNext,
    );
    routeObserver.subscribe(callbacks, route);
    return () => routeObserver.unsubscribe(callbacks);
  }, [route, routeObserver, ...keys]);
}
