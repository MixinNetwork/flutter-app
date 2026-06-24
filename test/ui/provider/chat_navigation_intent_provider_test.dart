import 'package:flutter_app/ui/provider/chat_navigation_intent_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requestLatestJump emits a fresh one-shot key each time', () {
    final notifier = ChatNavigationIntentNotifier()..requestLatestJump();
    final firstKey = notifier.state.latestJumpRequestKey;

    notifier.requestLatestJump();

    expect(firstKey, isNotNull);
    expect(notifier.state.latestJumpRequestKey, isNotNull);
    expect(notifier.state.latestJumpRequestKey, isNot(same(firstKey)));
  });
}
