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

  Stream<T?> watchSingleOrNullThrottle(
    Duration duration,
  ) =>
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
