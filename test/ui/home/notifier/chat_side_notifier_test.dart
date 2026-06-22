import 'package:flutter_app/ui/home/conversation_info_destination.dart';
import 'package:flutter_app/ui/home/notifier/chat_side_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggles destinations without storing pages in state', () {
    final notifier = ChatSideNotifier();
    addTearDown(notifier.dispose);

    notifier.toggleDestination(ConversationInfoDestination.pinMessages);
    expect(notifier.state.destinations, [
      ConversationInfoDestination.pinMessages,
    ]);

    notifier.toggleDestination(ConversationInfoDestination.pinMessages);
    expect(notifier.state.destinations, isEmpty);
  });

  test('route-mode content jump closes the side stack', () {
    final notifier = ChatSideNotifier();
    addTearDown(notifier.dispose);

    notifier
      ..openDestination(ConversationInfoDestination.searchMessageHistory)
      ..routeMode = true
      ..closeAfterContentJump();

    expect(notifier.state.destinations, isEmpty);
  });

  test('empty stack pop is ignored', () {
    final notifier = ChatSideNotifier();
    addTearDown(notifier.dispose);

    notifier.pop();

    expect(notifier.state.destinations, isEmpty);
  });
}
