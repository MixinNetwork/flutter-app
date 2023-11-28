part of '../extension.dart';

extension DurationToMinutesSecondsExtension on Duration {
  String get asMinutesSeconds {
    var duration = this;
    if (this < const Duration(seconds: 1)) {
      duration = const Duration(milliseconds: 1000);
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String get asMinutesSecondsWithDas {
    final minutes = inMinutes.toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    final das = (inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$minutes:$seconds.$das';
  }

  String formatAsConversationExpireIn({Localization? localization}) {
    final l10n = localization ?? Localization.current;
    if (inSeconds < 1) {
      return l10n.close;
    }
    if (inSeconds < 60) {
      return '$inSeconds ${l10n.unitSecond(inSeconds)}';
    } else if (inMinutes < 60) {
      return '$inMinutes ${l10n.unitMinute(inMinutes)}';
    } else if (inHours < 24) {
      return '$inHours ${l10n.unitHour(inHours)}';
    } else if (inDays < 7) {
      return '$inDays ${l10n.unitDay(inDays)}';
    }
    final inWeeks = inDays ~/ 7;
    return '$inWeeks ${l10n.unitWeek(inWeeks)}';
  }
}
