import 'package:intl/intl.dart';

String convertStringTime(DateTime _dateTime) {
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
