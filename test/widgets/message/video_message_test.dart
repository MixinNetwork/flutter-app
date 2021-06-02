import 'package:flutter_app/widgets/message/item/video_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test format video duration', () {
    var duration = const Duration(minutes: 12, seconds: 20);
    expect(formatVideoDuration(duration), '12:20');

    duration = const Duration(seconds: 20);
    expect(formatVideoDuration(duration), '00:20');

    duration = const Duration(seconds: 120);
    expect(formatVideoDuration(duration), '02:00');

    duration = const Duration(minutes: 1200, seconds: 20);
    expect(formatVideoDuration(duration), '1200:20');

    duration = const Duration(minutes: 120, seconds: 20);
    expect(formatVideoDuration(duration), '120:20');

    duration = const Duration(seconds: 121);
    expect(formatVideoDuration(duration), '02:01');
  });
}
