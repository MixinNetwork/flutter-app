import 'package:intl/intl.dart';

import '../generated/l10n.dart';

final _dateFormats = <(String, String), DateFormat>{};

/// A shared [DateFormat] for [skeleton] in the current locale. Creating a
/// [DateFormat] parses its pattern and costs about 30 times more than a
/// format, and every chat and conversation row formats a time.
DateFormat cachedDateFormat(String skeleton) => _dateFormats.putIfAbsent(
  (skeleton, Intl.getCurrentLocale()),
  () => DateFormat(skeleton),
);

extension DateTimeExtension on DateTime {
  String get format {
    final now = DateTime.now().toLocal();
    final dateTime = toLocal();
    if (isSameDay(now, dateTime)) {
      return cachedDateFormat(DateFormat.HOUR24_MINUTE).format(dateTime);
    }
    if (isSameWeek(now, dateTime)) {
      return cachedDateFormat(DateFormat.ABBR_WEEKDAY).format(dateTime);
    }
    if (isSameYear(now, dateTime)) {
      return cachedDateFormat(DateFormat.ABBR_MONTH_DAY).format(dateTime);
    }
    return cachedDateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(dateTime);
  }

  String get formatOfDay {
    final now = DateTime.now().toLocal();
    final dateTime = toLocal();
    if (isSameDay(now, dateTime)) {
      return Localization.current.today;
    }
    if (isSameYear(now, dateTime)) {
      return cachedDateFormat(
        DateFormat.ABBR_MONTH_WEEKDAY_DAY,
      ).format(dateTime);
    }
    return cachedDateFormat(
      DateFormat.YEAR_ABBR_MONTH_WEEKDAY_DAY,
    ).format(dateTime);
  }

  bool get isToady => isSameDay(DateTime.now(), this);

  int get epochNano => microsecondsSinceEpoch * 1000;
}

extension StringEpochNanoExtension on String {
  int get epochNano => DateTime.tryParse(this)?.epochNano ?? 0;
}

bool isSameYear(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  final _a = a.toLocal();
  final _b = b.toLocal();
  return _a.year == _b.year;
}

bool isSameWeek(DateTime a, DateTime b) =>
    isSameDay(startOfWeek(a.toLocal()), startOfWeek(b.toLocal()));

DateTime startOfWeek(DateTime a) => a.subtract(Duration(days: a.weekday));

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  final _a = a.toLocal();
  final _b = b.toLocal();
  return _a.year == _b.year && _a.month == _b.month && _a.day == _b.day;
}
