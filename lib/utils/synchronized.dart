import 'dart:async';

/// A single asynchronous lock implemented by future-chaining.
class Lock {
  Future<void>? _last;

  /// Waits for previous [synchronized]-calls on this [Lock] to complete, and
  /// then calls [block] before further [synchronized] calls are allowed.
  Future<T> synchronized<T>(FutureOr<T> Function() block) {
    final previous = _last;
    // This completer may not be sync: It must complete just after
    // callBlockAndComplete completes.
    final blockCompleted = Completer<void>();
    _last = blockCompleted.future;

    Future<T> callBlockAndComplete() =>
        Future.sync(block).whenComplete(blockCompleted.complete);

    return previous != null
        ? previous.then((_) => callBlockAndComplete())
        : callBlockAndComplete();
  }
}
