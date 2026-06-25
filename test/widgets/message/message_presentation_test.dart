import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/widgets/message/message_presentation.dart';
import 'package:flutter_app/widgets/message/message_rows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test('shows sender for first incoming group message', () {
    final message = testMessage(1, userId: 'alice', userFullName: 'Alice');
    final presentation = MessagePresentation.fromRow(
      row: MessageRowModel(message: message),
      isGroupOrBotGroupConversation: true,
      enableShowAvatar: true,
      canShowUnreadBar: false,
      lastReadMessageId: null,
    );

    expect(presentation.isCurrentUser, false);
    expect(presentation.showAvatar, true);
    expect(presentation.userName, 'Alice');
    expect(presentation.userId, 'alice');
    expect(presentation.showNip, false);
  });

  test('hides repeated sender in the same incoming run', () {
    final previous = testMessage(1, userId: 'alice', userFullName: 'Alice');
    final message = testMessage(2, userId: 'alice', userFullName: 'Alice');
    final next = testMessage(3, userId: 'alice', userFullName: 'Alice');
    final presentation = MessagePresentation.fromRow(
      row: MessageRowModel(message: message, prev: previous, next: next),
      isGroupOrBotGroupConversation: true,
      enableShowAvatar: true,
      canShowUnreadBar: false,
      lastReadMessageId: null,
    );

    expect(presentation.userName, isNull);
    expect(presentation.showNip, false);
  });

  test('marks unread bar only when the row has a newer message', () {
    final message = testMessage(2);
    final presentation = MessagePresentation.fromRow(
      row: MessageRowModel(message: message, next: testMessage(3)),
      isGroupOrBotGroupConversation: false,
      enableShowAvatar: false,
      canShowUnreadBar: true,
      lastReadMessageId: message.messageId,
    );

    expect(presentation.showUnreadBar, true);
  });
}

MessageItem testMessage(
  int index, {
  String userId = 'user',
  String userFullName = 'User',
}) => MessageItem(
  messageId: '$index',
  conversationId: 'conversation',
  type: 'PLAIN_TEXT',
  createdAt: DateTime(2026, 1, 1, 12, index),
  status: MessageStatus.read,
  userId: userId,
  userFullName: userFullName,
  userIdentityNumber: '0',
  isVerified: false,
  sharedUserIsVerified: false,
  pinned: false,
);
