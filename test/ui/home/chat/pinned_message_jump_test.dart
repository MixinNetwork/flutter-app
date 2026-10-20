import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/chat/chat_scroll_coordinator.dart';
import 'package:flutter_app/ui/home/chat/message_jump.dart';
import 'package:flutter_app/ui/home/conversation_info_destination.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/home/notifier/chat_side_notifier.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_scroll_coordinator_test.dart' as fixtures;

class _Blink implements BlinkNotifier {
  @override
  void blinkByMessageId(String id) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messages implements MessageController {
  _Messages(this.onLoad);
  final void Function(String) onLoad;
  @override
  MessageState get state => MessageState();
  @override
  Future<MessageWindowDirection?> restoreDirectionFromSource({
    required String? sourceMessageId,
    required String targetMessageId,
  }) async => null;
  @override
  void loadAroundMessage(String messageId) => onLoad(messageId);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final narrow in [false, true]) {
    for (final targetIndex in [4, 24]) {
      testWidgets('pinned locate repeated narrow=$narrow target=$targetIndex', (
        tester,
      ) async {
        final coordinator = ChatScrollCoordinator();
        final side = ChatSideNotifier();
        final messages = List.generate(30, fixtures.testMessage);
        final keys = {for (final m in messages) m.messageId: GlobalKey()};
        final target = messages[targetIndex].messageId;
        final timeline = ChatTimelineLocation(
          blinkNotifier: _Blink(),
          scrollCoordinator: coordinator,
          messageController: _Messages((messageId) {
            coordinator.scheduleRestore(
              messages: messages,
              keysByMessageId: keys,
              reset: true,
              isLatest: false,
              centerMessageId: messageId,
            );
            // Stand in for the frame scheduled by the loaded message state.
            tester.binding.scheduleFrame();
          }),
        );
        final chat = SingleChildScrollView(
          key: coordinator.viewportKey,
          controller: coordinator.scrollController,
          child: Column(
            children: [
              for (final m in messages)
                SizedBox(key: keys[m.messageId], height: 80),
            ],
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: ListenableBuilder(
              listenable: side,
              builder: (context, _) {
                final panel = side.state.destinations.isNotEmpty;
                return narrow
                    ? Navigator(
                        onDidRemovePage: (_) {},
                        pages: [
                          MaterialPage(child: chat),
                          if (panel)
                            const MaterialPage(
                              child: Scaffold(body: Text('pinned')),
                            ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: chat),
                          if (panel)
                            const SizedBox(width: 200, child: Text('pinned')),
                        ],
                      );
              },
            ),
          ),
        );
        coordinator.updateMessages(messages, keys);
        for (var attempt = 0; attempt < 2; attempt++) {
          coordinator.scrollController.jumpTo(0);
          side.openDestination(ConversationInfoDestination.pinMessages);
          await tester.pumpAndSettle();
          var completed = false;
          final future = timeline
              .jumpToMessage(
                target,
                chatSideNotifier: side,
                closeSideAfterJump: true,
                chatSideRouteMode: narrow,
              )
              .then((_) => completed = true);
          await tester.pumpAndSettle();
          expect(
            completed,
            true,
            reason: 'Locate must complete with panel open',
          );
          await future;
          await tester.pump();
          await tester.pumpAndSettle();
          expect(
            fixtures.messageTop(coordinator, keys[target]!),
            closeTo(
              coordinator.scrollController.position.viewportDimension *
                  ChatScrollCoordinator.messageFocusAnchor,
              0.5,
            ),
          );
          expect(side.state.destinations.isEmpty, narrow);
        }
        await tester.pumpWidget(const SizedBox());
        coordinator.dispose();
        side.dispose();
      });
    }
  }
}
