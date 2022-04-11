part of '../extension.dart';

extension DurationToMinutesSecondsExtension on Duration {
  String get asMinutesSeconds {
    var duration = this;
    if (inMilliseconds < 1000) {
      duration = const Duration(milliseconds: 1000);
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String formatAsConversationExpireIn({Localization? localization}) {
    final l10n = localization ?? Localization.current;
    if (inSeconds < 1) {
      return l10n.off;
    }
    if (inSeconds < 60) {
      if (inSeconds == 1) {
        return '1 ${l10n.second}';
      }
      return '$inSeconds ${l10n.seconds}';
    } else if (inMinutes < 60) {
      if (inMinutes == 1) {
        return '1 ${l10n.minute}';
      }
      return '$inMinutes ${l10n.minutes}';
    } else if (inHours < 24) {
      if (inHours == 1) {
        return '1 ${l10n.hour}';
      }
      return '$inHours ${l10n.hours}';
    } else if (inDays < 7) {
      if (inDays == 1) {
        return '1 ${l10n.day}';
      }
      return '$inDays ${l10n.days}';
    }
    return '${inDays ~/ 7} ${l10n.weeks}';
  }
}
