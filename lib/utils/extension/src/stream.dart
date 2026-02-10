part of '../extension.dart';

extension ThrottleExtensions<T> on Stream<T> {
  Stream<T> throttleTime(Duration duration) {
    DateTime? lastTime;
    Timer? timer;
    late T lastData;

    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          void add(T event) {
            timer?.cancel();
            timer = null;
            lastTime = DateTime.now();
            sink.add(event);
          }

          if (lastTime == null) {
            add(data);
          } else {
            final now = DateTime.now();
            final diff = now.difference(lastTime!);
            if (diff >= duration) {
              add(data);
            } else {
              lastData = data;
              timer?.cancel();
              timer = Timer(duration - diff, () {
                add(lastData);
              });
            }
          }
        },
        handleDone: (sink) {
          timer?.cancel();
          sink.close();
        },
      ),
    );
  }
}

extension StreamExtensionWhereNotNull<T> on Stream<T?> {
  Stream<T> whereNotNull() => where((e) => e != null).cast<T>();
}

extension StreamExtension<T> on Stream<T> {
  StreamSubscription<T> asyncDropListen<E>(
    Future<void> Function(T event) convert,
  ) {
    T? lastEvent;
    var running = false;
    final lock = Lock();

    return listen((event) async {
      if (running) {
        lastEvent = event;
        return;
      }
      // ensure only one event is processed at a time
      await lock.synchronized(() async {
        running = true;
        await convert(event);
        while (true) {
          final e = lastEvent;
          if (e == null) break;
          lastEvent = null;
          await convert(e);
        }
        running = false;
      });
    });
  }

  StreamSubscription asyncListen<E>(
    FutureOr<E> Function(T event) convert, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => asyncMap((e) => convert(e)).listen(
    (_) {},
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  Stream<E> asyncBufferMap<E>(FutureOr<E> Function(List<T> event) convert) {
    StreamController<E> controller;
    controller = isBroadcast
        ? StreamController<E>.broadcast()
        : StreamController<E>();

    final events = <T>[];
    var querying = false;

    controller.onListen = () {
      final subscription = listen(
        null,
        onError: controller.addError,
        onDone: controller.close,
      );
      FutureOr<void> add(E value) {
        controller.add(value);
      }

      final addError = controller.addError;

      void onData([bool force = false]) {
        if (querying && !force) return;
        if (events.isEmpty) {
          querying = false;
          return;
        }

        FutureOr<E> newValue;
        final list = events.toList();
        events.clear();
        try {
          newValue = convert(list);
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }
        if (newValue is Future<E>) {
          querying = true;
          newValue.then(add, onError: addError).whenComplete(() {
            if (events.isNotEmpty) return onData(true);
            querying = false;
          });
        } else {
          controller.add(newValue);
        }
      }

      subscription.onData((event) {
        events.add(event);
        onData();
      });
      controller.onCancel = subscription.cancel;
      if (!isBroadcast) {
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume;
      }
    };
    return controller.stream;
  }
}
