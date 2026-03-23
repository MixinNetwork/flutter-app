import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/extension/extension.dart';

final minuteTimerProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  );
});

final formattedDateTimeProvider = Provider.family<String, DateTime>((
  ref,
  dateTime,
) {
  ref.watch(minuteTimerProvider);
  return dateTime.format;
});

final formattedDayProvider = Provider.family<String, DateTime>((ref, dateTime) {
  ref.watch(minuteTimerProvider);
  return dateTime.formatOfDay;
});
