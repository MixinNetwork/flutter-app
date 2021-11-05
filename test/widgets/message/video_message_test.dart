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
}
