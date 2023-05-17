part of '../extension.dart';

const kDefaultThrottleDuration = Duration(milliseconds: 333);
const kSlowThrottleDuration = Duration(seconds: 1);
const kVerySlowThrottleDuration = Duration(seconds: 3);

extension SelectedableThrottle<T> on Selectable<T> {
  Stream<Value> _watchWithStream<Value>({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    required Future<Value> Function() fetch,
    bool prepend = true,
  }) {
    var stream = Rx.merge(eventStreams).throttleTime(duration);
    if (prepend) stream = stream.startWith([]);
    return stream.asyncBufferMap((_) => fetch());
  }

  Stream<List<T>> watchWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        prepend: prepend,
        fetch: get,
      );

  Stream<T> watchSingleWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        prepend: prepend,
        fetch: getSingle,
      );

  Stream<T?> watchSingleOrNullWithStream({
    required Iterable<Stream<dynamic>> eventStreams,
    required Duration duration,
    bool prepend = true,
  }) =>
      _watchWithStream(
        eventStreams: eventStreams,
        duration: duration,
        prepend: prepend,
        fetch: getSingleOrNull,
      );
}
