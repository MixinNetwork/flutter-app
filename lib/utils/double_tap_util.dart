import 'dart:async';
import 'dart:ui';

Map<String, Timer> _timers = {};

void doubleTap(String tag, Duration duration, VoidCallback onExecute) {
  final timer = _timers[tag];

  if (duration == Duration.zero) {
    timer?.cancel();
    _timers.remove(tag);
    onExecute();
  } else {
    if (timer != null && timer.isActive) {
      onExecute();
    }

    _timers.remove(tag);
    timer?.cancel();

    _timers[tag] = Timer(duration, () {
      _timers.remove(tag);
      timer?.cancel();
    });
  }
}
