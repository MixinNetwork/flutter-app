part of '../extension.dart';

extension StreamExtensionWhereNotNull<T> on Stream<T?> {
  Stream<T> whereNotNull() => where((e) => e != null).cast<T>();
}

extension StreamExtension<T> on Stream<T> {
  StreamSubscription asyncListen<E>(FutureOr<E> Function(T event) convert) =>
      asyncMap((e) => convert(e)).listen((_) {});

  Stream<E> asyncBufferMap<E>(FutureOr<E> Function(List<T> event) convert) {
    StreamController<E> controller;
    if (isBroadcast) {
      controller = StreamController<E>.broadcast();
    } else {
      controller = StreamController<E>();
    }

    final events = <T>[];
    var querying = false;

    controller.onListen = () {
      final subscription =
          listen(null, onError: controller.addError, onDone: controller.close);
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

      subscription.onData((T event) {
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
