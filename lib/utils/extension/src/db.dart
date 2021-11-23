part of '../extension.dart';

const _kDefaultThrottleDuration = Duration(milliseconds: 50);

extension SelectedableThrottle<T> on Selectable<T> {
  Stream<List<T>> watchThrottle({
    Duration duration = _kDefaultThrottleDuration,
  }) =>
      watch().throttled(duration);

  Stream<T> watchSingleThrottle({
    Duration duration = _kDefaultThrottleDuration,
  }) =>
      watchSingle().throttled(duration);

  Stream<T?> watchSingleOrNullThrottle({
    Duration duration = _kDefaultThrottleDuration,
  }) =>
      watchSingleOrNull().throttled(duration);
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
