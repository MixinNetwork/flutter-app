import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/chat/chat_scroll_coordinator.dart';
import 'package:flutter_app/ui/home/chat/chat_timeline_window.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test('unread center is rendered in top and replaced by separator anchor', () {
    final center = testMessage(10);
    final window = ChatTimelineWindow(
      MessageState(
        conversationId: 'conversation',
        top: [testMessage(1)],
        center: center,
        bottom: [testMessage(11)],
        lastReadMessageId: center.messageId,
      ),
    );

    expect(window.anchorUnreadSeparator, true);
    expect(window.scrollAnchor, ChatScrollCoordinator.unreadSeparatorAnchor);
    expect(window.restoreCenterMessageId, isNull);
    expect(window.rows.center, isNull);
    expect(window.rows.top.map((row) => row.message.messageId), ['1', '10']);
  });

  test('ordinary center remains the restore target', () {
    final center = testMessage(10);
    final window = ChatTimelineWindow(
      MessageState(
        conversationId: 'conversation',
        top: [testMessage(1)],
        center: center,
        bottom: [testMessage(11)],
        lastReadMessageId: '2',
      ),
    );

    expect(window.anchorUnreadSeparator, false);
    expect(window.scrollAnchor, ChatScrollCoordinator.messageFocusAnchor);
    expect(window.restoreCenterMessageId, center.messageId);
    expect(window.rows.center?.message.messageId, center.messageId);
  });

  test('latest reset animation is limited to same conversation refreshes', () {
    final refreshKey = Object();
    final window = ChatTimelineWindow(
      MessageState(
        conversationId: 'conversation',
        bottom: [testMessage(11)],
        isLatest: true,
        refreshKey: refreshKey,
      ),
    );

    expect(
      window.animateLatestReset(
        previousConversationId: 'conversation',
        previousRefreshKey: Object(),
      ),
      true,
    );
    expect(
      window.animateLatestReset(
        previousConversationId: 'other',
        previousRefreshKey: refreshKey,
      ),
      false,
    );
  });
}

MessageItem testMessage(int index) => MessageItem(
  messageId: '$index',
  conversationId: 'conversation',
  type: 'PLAIN_TEXT',
  createdAt: DateTime(2026, 1, 1, 12, index),
  status: MessageStatus.read,
  userId: 'user',
  userIdentityNumber: '0',
  isVerified: false,
  sharedUserIsVerified: false,
  pinned: false,
);
