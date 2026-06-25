import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not expose a database read point as an unread boundary', () {
    expect(
      resolveMessageWindowLastReadMessageId(
        requestedLastReadMessageId: null,
        unseenMessageCount: 0,
        conversationLastReadMessageId: 'read-point',
      ),
      isNull,
    );
  });

  test('uses the conversation read point when there are unread messages', () {
    expect(
      resolveMessageWindowLastReadMessageId(
        requestedLastReadMessageId: null,
        unseenMessageCount: 1,
        conversationLastReadMessageId: 'read-point',
      ),
      'read-point',
    );
  });
}
