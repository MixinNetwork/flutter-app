import 'package:flutter_app/utils/datetime_format_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh'));
  tearDown(() => Intl.defaultLocale = null);

  test('reuses a date format until the locale changes', () {
    Intl.defaultLocale = 'en';
    final english = cachedDateFormat(DateFormat.ABBR_WEEKDAY);
    expect(cachedDateFormat(DateFormat.ABBR_WEEKDAY), same(english));

    Intl.defaultLocale = 'zh';
    final chinese = cachedDateFormat(DateFormat.ABBR_WEEKDAY);
    expect(chinese, isNot(same(english)));
    expect(chinese.locale, 'zh');
    expect(chinese.format(DateTime(2026, 10, 12)), '周一');
  });

  test('compares local days of UTC and local times', () {
    final morning = DateTime(2026, 10, 15, 0, 30);
    final night = DateTime(2026, 10, 15, 23, 30);
    expect(isSameDay(morning.toUtc(), night), isTrue);
    expect(isSameDay(morning.toUtc(), morning.toUtc()), isTrue);
    expect(isSameDay(night, DateTime(2026, 10, 16, 0, 10).toUtc()), isFalse);
    expect(isSameDay(null, night), isFalse);
  });
}
