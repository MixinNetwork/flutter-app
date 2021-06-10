import 'package:intl/intl.dart';

import '../../generated/l10n.dart';

String formatDateTime(DateTime _dateTime) {
  final now = DateTime.now().toLocal();
  final dateTime = _dateTime.toLocal();
  if (isSameDay(now, dateTime)) {
    return DateFormat.Hm().format(dateTime);
  }
  if (isSameWeek(now, dateTime)) {
    return DateFormat.EEEE().format(dateTime);
  }
  if (isSameYear(now, dateTime)) {
    return DateFormat.MMMd().format(dateTime);
  }
  return DateFormat.yMMMd().format(dateTime);
}

String formatDateTimeOfDay(DateTime _dateTime) {
  final now = DateTime.now().toLocal();
  final dateTime = _dateTime.toLocal();
  if (isSameDay(now, dateTime)) {
    return Localization.current.today;
  }
  if (isSameYear(now, dateTime)) {
    return DateFormat.MMMEd().format(dateTime);
  }
  return DateFormat.yMMMEd().format(dateTime);
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

bool within24Hours(DateTime? _dateTime) {
  if (_dateTime == null) return false;
  final now = DateTime.now();
  final offset = now.millisecondsSinceEpoch - _dateTime.millisecondsSinceEpoch;
  if (offset < 60 * 60 * 1000 * 24) {
    return true;
  }
  return false;
}
