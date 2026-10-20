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

// The local day of a time, by instance. Each local date field reads the time
// zone, and chat rows compare the day of every message with its neighbours
// whenever the message window changes.
// shortcut: a time zone change while the app runs keeps the old local days of
// cached instances, until the messages load again.
final _localDays = Expando<int>();

/// The local day of [time] as yyyymmdd, cached by instance.
int localDay(DateTime time) => _localDays[time] ??= () {
  final local = time.toLocal();
  return local.year * 10000 + local.month * 100 + local.day;
}();

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return localDay(a) == localDay(b);
}
