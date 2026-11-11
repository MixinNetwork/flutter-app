import 'package:flutter_app/widgets/message/send_message_dialog/send_recipient.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the confirmation names the recipient by name and Mixin ID', () {
    expect(
      recipientLine(userId: 'u-1', fullName: 'Alice', identityNumber: '7000'),
      'Alice (7000)',
    );
  });

  test('a recipient without a name shows its Mixin ID, and one not loaded yet '
      'shows the raw id', () {
    expect(
      recipientLine(userId: 'u-1', fullName: ' ', identityNumber: '7000'),
      '7000',
    );
    expect(recipientLine(userId: 'u-1', fullName: 'Alice'), 'Alice');
    expect(recipientLine(userId: 'u-1'), 'u-1');
  });
}
