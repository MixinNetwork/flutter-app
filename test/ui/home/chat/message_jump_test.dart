import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/chat/chat_scroll_coordinator.dart';
import 'package:flutter_app/ui/home/chat/message_jump.dart';
import 'package:flutter_app/ui/home/conversation_info_destination.dart';
import 'package:flutter_app/ui/home/desktop_shell_layout.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/home/notifier/chat_side_notifier.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _BlinkNotifier implements BlinkNotifier {
  @override
  void blinkByMessageId(String messageId) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScrollCoordinator implements ChatScrollCoordinator {
  @override
  Future<bool> scrollToMessageIfInLoadedWindow(
    String messageId, {
    bool animated = false,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessageController implements MessageController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessageJumpHarness extends StatelessWidget {
  const _MessageJumpHarness({
    required this.chatSideNotifier,
    required this.timeline,
  });

  final ChatSideNotifier chatSideNotifier;
  final ChatTimelineLocation timeline;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: DesktopShellLayout.chatSideRouteMode(
      routeMode: true,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<ChatSideNotifier>.value(
            value: chatSideNotifier,
          ),
          Provider<ChatTimelineLocation>.value(value: timeline),
        ],
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              context.jumpToMessageInChat(
                'target-message',
                closeSideAfterJump: true,
              );
            },
            child: const Text('jump'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'a message jump closes the current narrow search after its notifier changes',
    (tester) async {
      final firstNotifier = ChatSideNotifier()
        ..openDestination(ConversationInfoDestination.searchMessageHistory);
      final currentNotifier = ChatSideNotifier()
        ..openDestination(ConversationInfoDestination.searchMessageHistory);
      addTearDown(firstNotifier.dispose);
      addTearDown(currentNotifier.dispose);

      final timeline = ChatTimelineLocation(
        blinkNotifier: _BlinkNotifier(),
        scrollCoordinator: _ScrollCoordinator(),
        messageController: _MessageController(),
      );

      await tester.pumpWidget(
        _MessageJumpHarness(
          chatSideNotifier: firstNotifier,
          timeline: timeline,
        ),
      );
      await tester.pumpWidget(
        _MessageJumpHarness(
          chatSideNotifier: currentNotifier,
          timeline: timeline,
        ),
      );

      await tester.tap(find.text('jump'));
      await tester.pump();

      expect(currentNotifier.state.destinations, isEmpty);
    },
  );
}
