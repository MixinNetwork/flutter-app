import 'package:flutter_app/ui/provider/chat_navigation_intent_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requestLatestJump emits a fresh one-shot key each time', () {
    final notifier = ChatNavigationIntentNotifier()
      ..requestLatestJump('conversation-1');
    final firstKey = notifier.state.latestJumpRequestKey;

    notifier.requestLatestJump('conversation-1');

    expect(firstKey, isNotNull);
    expect(notifier.state.latestJumpRequestKey, isNotNull);
    expect(notifier.state.latestJumpRequestKey, isNot(same(firstKey)));
    expect(notifier.state.latestJumpConversationId, 'conversation-1');

    final requestKey = notifier.state.latestJumpRequestKey!;
    notifier.consumeLatestJump(requestKey);
    expect(notifier.state.latestJumpRequestKey, isNull);
    expect(notifier.state.latestJumpConversationId, isNull);
  });
}
