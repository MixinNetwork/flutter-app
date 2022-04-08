part of '../extension.dart';

extension DurationToMinutesSecondsExtension on Duration {
  String get asMinutesSeconds {
    var duration = this;
    if (inMilliseconds < 1000) {
      duration = const Duration(milliseconds: 1000);
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  String formatAsConversationExpireIn(BuildContext context) {
    if (inSeconds < 1) {
      return context.l10n.off;
    }
    if (inSeconds < 60) {
      if (inSeconds == 1) {
        return '1 ${context.l10n.second}';
      }
      return '$inSeconds ${context.l10n.seconds}';
    } else if (inMinutes < 60) {
      if (inMinutes == 1) {
        return '1 ${context.l10n.minute}';
      }
      return '$inMinutes ${context.l10n.minutes}';
    } else if (inHours < 24) {
      if (inHours == 1) {
        return '1 ${context.l10n.hour}';
      }
      return '$inHours ${context.l10n.hours}';
    } else if (inDays < 7) {
      if (inDays == 1) {
        return '1 ${context.l10n.day}';
      }
      return '$inDays ${context.l10n.days}';
    }
    return '${inDays ~/ 7} ${context.l10n.weeks}';
  }
}
