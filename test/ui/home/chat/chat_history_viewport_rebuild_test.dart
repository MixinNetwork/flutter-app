import 'package:flutter/material.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../integration_test/chat_timeline_fixture.dart';

void main() {
  setUpAll(EventBus.initialize);

  testWidgets('an incoming message rebuilds only itself and its neighbour', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final messages = buildMessages(81, imagePath: '', withImages: false);
    final controller = FakeMessageController(
      messages.sublist(0, 80),
      initial: 80,
    );
    await tester.pumpWidget(
      ChatTimelineFixture(
        controller: controller,
        blinkNotifier: BlinkNotifier(tester),
        database: createFixtureDatabase(),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final widget = element.widget;
      if (widget is MessageItemWidget) rebuilt.add(widget.message.messageId);
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    controller.append(messages.last);
    await tester.pump();

    expect(rebuilt.toSet(), {messages[79].messageId, messages[80].messageId});

    debugOnRebuildDirtyWidget = null;
    await tester.pumpWidget(const SizedBox());
    // isBotGroupProvider closes its keep-alive 10 minutes after dispose.
    await tester.pump(const Duration(minutes: 11));
  });
}
