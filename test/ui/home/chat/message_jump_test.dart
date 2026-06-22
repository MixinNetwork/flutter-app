import 'package:flutter_app/ui/home/chat/message_jump.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('latest jump only uses loaded window when message state is latest', () {
    expect(
      shouldUseLoadedLatestWindowForLatestJump(MessageState(isLatest: true)),
      isTrue,
    );
    expect(
      shouldUseLoadedLatestWindowForLatestJump(MessageState()),
      isFalse,
    );
  });

  test('chat jump target carries side close policy', () {
    const target = ChatJumpTarget.message(
      'message',
      sourceMessageId: 'source',
      closeSideAfterJump: true,
    );

    expect(target.kind, ChatJumpKind.message);
    expect(target.messageId, 'message');
    expect(target.sourceMessageId, 'source');
    expect(target.closeSideAfterJump, isTrue);
  });
}
