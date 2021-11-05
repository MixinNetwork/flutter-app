part of '../extension.dart';

extension DurationToMinutesSecondsExtension on Duration {
  String get asMinutesSeconds {
    var duration = this;
    if (inMilliseconds < 1000) {
      duration = const Duration(milliseconds: 1000);
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
