part of '../extension.dart';

const kDefaultThrottleDuration = Duration(milliseconds: 333);
const kSlowThrottleDuration = Duration(seconds: 1);
const kVerySlowThrottleDuration = Duration(seconds: 3);

extension SelectedableThrottle<T> on Selectable<T> {
  Stream<List<T>> watchThrottle(
    Duration duration,
  ) =>
      watch().throttled(duration);

  Stream<T> watchSingleThrottle(
    Duration duration,
  ) =>
      watchSingle().throttled(duration);

  Stream<Value> _watchWithStream<Value>({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    required Future<Value> Function() fetch,
    bool trailing = false,
    bool prepend = true,
  }) {
    var stream = Rx.merge(eventStreams);
    if (prepend) stream = stream.startWith([]);
    return stream
        .throttleTime(duration, trailing: trailing)
        .asyncBufferMap((_) => fetch());
  }

  Stream<List<T>> watchWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool trailing = false,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        trailing: trailing,
        prepend: prepend,
        fetch: get,
      );

  Stream<T> watchSingleWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool trailing = false,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        trailing: trailing,
        prepend: prepend,
        fetch: getSingle,
      );

  Stream<T?> watchSingleOrNullWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool trailing = false,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        trailing: trailing,
        prepend: prepend,
        fetch: getSingleOrNull,
      );
}

extension _ThrottleWithPause<T> on Stream<T> {
  Stream<T> throttled(Duration duration) => Stream.multi(
        (listener) {
          late final StreamSubscription<T> subscription;

          void onEvent() {
            subscription.pause(Future.delayed(duration));
          }

          subscription = listen(
            (event) {
              onEvent();
              listener.addSync(event);
            },
            onError: (Object e, StackTrace s) {
              onEvent();
              listener.addErrorSync(e, s);
            },
            onDone: () {
              subscription.cancel();
              listener.closeSync();
            },
          );

          listener
            ..onPause = subscription.pause
            ..onResume = subscription.resume
            ..onCancel = subscription.cancel;
        },
        isBroadcast: isBroadcast,
      );
}
