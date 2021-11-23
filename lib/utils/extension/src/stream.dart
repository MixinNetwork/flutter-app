part of '../extension.dart';

extension StreamExtensionWhereNotNull<T> on Stream<T?> {
  Stream<T> whereNotNull() => where((e) => e != null).cast<T>();
}

extension StreamExtension<T> on Stream<T> {
  StreamSubscription<T> asyncDropListen<E>(
      FutureOr<E> Function(T event) convert) {
    final subscription = listen(null);

    var drop = false;
    void resume() {
      drop = false;
    }

    subscription.onData((T event) {
      if (drop) return;

      FutureOr<E> newValue;
      try {
        newValue = convert(event);
      } catch (_) {
        return;
      }
      if (newValue is Future<E>) {
        drop = true;
        newValue.whenComplete(resume).catchError((_) {
          resume();
        });
      }
    });

    return subscription;
  }

  StreamSubscription<T> asyncListen<E>(FutureOr<E> Function(T event) convert) {
    final subscription = listen(null);

    void resume() {
      subscription.resume();
    }

    subscription.onData((T event) {
      FutureOr<E> newValue;
      try {
        newValue = convert(event);
      } catch (_) {
        return;
      }
      if (newValue is Future<E>) {
        subscription.pause();
        newValue.whenComplete(resume).catchError((_) {
          resume();
        });
      }
    });

    return subscription;
  }
}
