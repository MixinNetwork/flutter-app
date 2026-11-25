import 'package:flutter/widgets.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/utils/message_optimize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Localization.load(const Locale('en')));

  String text({
    String? participantUserId,
    String? participantFullName,
    String? senderId = 'sender',
    String? senderFullName = 'Sender',
  }) => recalledMessageText(
    participantUserId: participantUserId,
    participantFullName: participantFullName,
    senderId: senderId,
    senderFullName: senderFullName,
    isCurrentUser: (actorId) => actorId == 'me',
  );

  test('names the user who recalled the message', () {
    expect(
      text(participantUserId: 'admin', participantFullName: 'Admin'),
      'Admin deleted this message.',
    );
    expect(
      text(participantUserId: 'me', participantFullName: 'Me'),
      'You deleted this message',
    );
    expect(text(participantUserId: 'admin'), 'This message was deleted');
  });

  test('falls back to the sender without a recorded actor', () {
    expect(text(), 'Sender deleted this message.');
    expect(text(senderId: 'me'), 'You deleted this message');
    expect(text(senderFullName: null), 'This message was deleted');
  });
}
