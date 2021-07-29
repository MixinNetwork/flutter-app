import 'package:intl/intl.dart';

import '../../generated/l10n.dart';

extension DateTimeExtension on DateTime {
  String get format {
    final now = DateTime.now().toLocal();
    final dateTime = toLocal();
    if (isSameDay(now, dateTime)) {
      return DateFormat.Hm().format(dateTime);
    }
    if (isSameWeek(now, dateTime)) {
      return DateFormat.E().format(dateTime);
    }
    if (isSameYear(now, dateTime)) {
      return DateFormat.MMMd().format(dateTime);
    }
    return DateFormat.yMMMd().format(dateTime);
  }

  String get formatOfDay {
    final now = DateTime.now().toLocal();
    final dateTime = toLocal();
    if (isSameDay(now, dateTime)) {
      return Localization.current.today;
    }
    if (isSameYear(now, dateTime)) {
      return DateFormat.MMMEd().format(dateTime);
    }
    return DateFormat.yMMMEd().format(dateTime);
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
