import 'package:intl/intl.dart';

String convertStringTime(DateTime _dateTime) {
  final now = DateTime.now().toLocal();
  final dateTime = _dateTime.toLocal();
  if (isSameDay(now, dateTime)) {
    return DateFormat.jm().format(dateTime);
  }
  if (isYesterday(now, dateTime)) {
    return 'Yesterday';
  }
  if (isSameWeek(now, dateTime)) {
    return DateFormat.EEEE().format(dateTime);
  }
  return DateFormat.Md().format(dateTime);
}

bool isSameWeek(DateTime a, DateTime b) =>
    isSameDay(startOfWeek(a), startOfWeek(b));

DateTime startOfWeek(DateTime a) => a.subtract(Duration(days: a.weekday));

bool isYesterday(DateTime a, DateTime b) =>
    isSameDay(a.subtract(const Duration(days: 1)), b);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
