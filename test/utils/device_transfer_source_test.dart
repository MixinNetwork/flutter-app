import 'package:flutter_app/workers/device_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migration accepts only the current account primary session', () {
    final controller = DeviceTransferIsolateController(
      dispose: () {},
      handleRemoteCommand: (_) {},
      userId: 'self',
      primarySessionId: 'primary',
    );
    for (final source in [
      ('self', 'self', 'primary', true),
      ('other', 'other', 'primary', false),
      ('self', 'other', 'primary', false),
      ('other', 'self', 'primary', false),
      ('self', 'self', 'desktop', false),
      ('self', 'self', '', false),
    ]) {
      expect(
        controller.acceptsRemoteSource(
          sourceUserId: source.$1,
          senderId: source.$2,
          sessionId: source.$3,
        ),
        source.$4,
      );
    }
  });
}
