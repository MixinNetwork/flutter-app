import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/extension/extension.dart';
import '../../utils/rivepod.dart';

class MinuteTimerNotifier extends DistinctStateNotifier<DateTime> {
  MinuteTimerNotifier() : super(DateTime.now()) {
    timer = Timer.periodic(const Duration(minutes: 1), (_) => handleTimeout());
  }

  late Timer timer;

  void handleTimeout() => state = DateTime.now();

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}

final minuteTimerProvider =
    StateNotifierProvider<MinuteTimerNotifier, DateTime>(
      (ref) => MinuteTimerNotifier(),
    );

final formattedDateTimeProvider = Provider.family<String, DateTime>((
  ref,
  dateTime,
) {
  // for update this provider
  ref.watch(minuteTimerProvider);
  return dateTime.format;
});

final formattedDayProvider = Provider.family<String, DateTime>((ref, dateTime) {
  // for update this provider
  ref.watch(minuteTimerProvider);
  return dateTime.formatOfDay;
});
