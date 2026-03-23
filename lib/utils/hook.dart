import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../app.dart';
import 'app_lifecycle.dart';
import 'logger.dart';

AsyncSnapshot<T> useMemoizedFuture<T>(
  Future<T> Function() futureBuilder,
  T initialData, {
  List<Object?> keys = const <Object>[],
}) => _logSnapshotError(
  useFuture(useMemoized(futureBuilder, keys), initialData: initialData),
);

AsyncSnapshot<T> useMemoizedStream<T>(
  Stream<T> Function() valueBuilder, {
  T? initialData,
  List<Object?> keys = const <Object>[],
}) => _logSnapshotError(
  useStream<T>(
    useMemoized<Stream<T>>(valueBuilder, keys),
    initialData: initialData,
  ),
);

AsyncSnapshot<T> _logSnapshotError<T>(AsyncSnapshot<T> snapshot) {
  useEffect(() {
    if (snapshot.hasError) {
      e(
        'error: ${snapshot.error} ${snapshot.stackTrace}'
        '\n call stack: \n ${StackTrace.current}',
      );
    }
  }, [snapshot]);
  return snapshot;
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

  return useMemoized(
    () => streamController.stream.startWith(valueNotifier.value),
    [valueNotifier],
  );
}

AsyncSnapshot<T> useListenableConverter<L extends Listenable, T>(
  L listenable, {
  required T Function(L) converter,
  List<Object?> keys = const <Object>[],
}) {
  final streamController = useStreamController<T>(keys: [listenable, ...keys]);

  final initialData = useMemoized(() => converter(listenable));

  useEffect(() {
    void onListen() => streamController.add(converter(listenable));

    listenable.addListener(onListen);
    return () {
      listenable.removeListener(onListen);
    };
  }, [listenable, ...keys]);

  final stream = useMemoized(() => streamController.stream.distinct(), [
    listenable,
    ...keys,
  ]);
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

BuildContext? useSecondNavigatorContext(BuildContext context) => useMemoized(
  () {
    final rootNavigatorState = Navigator.maybeOf(context, rootNavigator: true);
    if (rootNavigatorState == null) return null;

    BuildContext? findSecondContext(BuildContext context) {
      final state = context.findAncestorStateOfType<NavigatorState>();
      if (state == null) return null;
      if (state == rootNavigatorState) return context;
      return findSecondContext(state.context);
    }

    return findSecondContext(context);
  },
  [],
);

class _ProtocolListener with ProtocolListener {
  _ProtocolListener(this.callback);

  final ValueChanged<String> callback;

  @override
  void onProtocolUrlReceived(String url) => callback(url);
}

void useProtocol(ValueChanged<String> callback) {
  useEffect(() {
    final listener = _ProtocolListener(callback);
    protocolHandler.addListener(listener);

    return () {
      protocolHandler.removeListener(listener);
    };
  }, [callback]);
}

ValueNotifier<bool> useImagePlaying(BuildContext context) {
  final secondContext = useSecondNavigatorContext(context);
  final isCurrentRoute = useRef(true);
  final playing = useState(true);

  final listener = useCallback(() {
    playing.value = isAppActive && isCurrentRoute.value;
  }, []);

  useRouteObserver(
    rootRouteObserver,
    context: secondContext,
    didPushNext: () {
      isCurrentRoute.value = false;
      listener();
    },
    didPopNext: () {
      isCurrentRoute.value = true;
      listener();
    },
  );

  useEffect(() {
    listener();
    appActiveListener.addListener(listener);
    return () => appActiveListener.removeListener(listener);
  }, []);
  return playing;
}
