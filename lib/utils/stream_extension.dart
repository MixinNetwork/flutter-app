import 'dart:async';

extension StreamExtension<T> on Stream<T> {
  Stream<E> asyncMapDrop<E>(FutureOr<E> Function(T event) convert) {
    StreamController<E> controller;
    if (isBroadcast) {
      controller = StreamController<E>.broadcast();
    } else {
      controller = StreamController<E>();
    }

    controller.onListen = () {
      final subscription = listen(null,
          onError: controller.addError, // Avoid Zone error replacement.
          onDone: controller.close);
      FutureOr<Null> add(E value) {
        controller.add(value);
      }

      var drop = false;
      final addError = controller.addError;
      void resume() {
        drop = false;
      }

      subscription.onData((T event) {
        if (drop) return;

        FutureOr<E> newValue;
        try {
          newValue = convert(event);
        } catch (e, s) {
          controller.addError(e, s);
          return;
        }
        if (newValue is Future<E>) {
          drop = true;
          newValue.then(add, onError: addError).whenComplete(resume);
        } else {
          controller.add(newValue as dynamic);
        }
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
