import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test format video duration', () {
    var duration = const Duration(minutes: 12, seconds: 20);
    expect(duration.asMinutesSeconds, '12:20');

    duration = const Duration(seconds: 20);
    expect(duration.asMinutesSeconds, '00:20');

    duration = const Duration(seconds: 120);
    expect(duration.asMinutesSeconds, '02:00');

    duration = const Duration(minutes: 1200, seconds: 20);
    expect(duration.asMinutesSeconds, '1200:20');

    duration = const Duration(minutes: 120, seconds: 20);
    expect(duration.asMinutesSeconds, '120:20');

    duration = const Duration(seconds: 121);
    expect(duration.asMinutesSeconds, '02:01');

    duration = const Duration(milliseconds: 999);
    expect(duration.asMinutesSeconds, '00:01');
  });

  test('test format duration asMinutesSecondsWithDas', () {
    var duration = const Duration(minutes: 12, seconds: 20);
    expect(duration.asMinutesSecondsWithDas, '12:20.0');

    duration = const Duration(seconds: 20);
    expect(duration.asMinutesSecondsWithDas, '00:20.0');

    duration = const Duration(seconds: 120, milliseconds: 999);
    expect(duration.asMinutesSecondsWithDas, '02:00.9');

    duration = const Duration(minutes: 1200, seconds: 20, milliseconds: 20);
    expect(duration.asMinutesSecondsWithDas, '1200:20.0');

    duration = const Duration(minutes: 120, seconds: 20, milliseconds: 120);
    expect(duration.asMinutesSecondsWithDas, '120:20.1');

    duration = const Duration(milliseconds: 999);
    expect(duration.asMinutesSecondsWithDas, '00:00.9');
  });
}
