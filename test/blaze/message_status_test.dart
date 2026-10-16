import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test('a receipt moves a sent message forward only', () {
    expect(
      canUpdateMessageStatus(MessageStatus.sending, MessageStatus.sent),
      isTrue,
    );
    expect(
      canUpdateMessageStatus(MessageStatus.sent, MessageStatus.read),
      isTrue,
    );
    expect(
      canUpdateMessageStatus(MessageStatus.read, MessageStatus.delivered),
      isFalse,
    );
    expect(
      canUpdateMessageStatus(MessageStatus.read, MessageStatus.read),
      isFalse,
    );
  });

  test('a receipt keeps a message that failed to decrypt waiting', () {
    // Its content is still the encrypted data, and only failed messages are
    // requested again from their sender.
    for (final next in MessageStatus.values) {
      expect(canUpdateMessageStatus(MessageStatus.failed, next), isFalse);
      expect(canUpdateMessageStatus(MessageStatus.unknown, next), isFalse);
    }
  });
}
