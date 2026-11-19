import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/ui/home/chat/chat_history_viewport.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/home/notifier/chat_side_notifier.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_app/ui/provider/keyword_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_app/widgets/message/item/text/text_message.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' show MessageStatus;
import 'package:provider/provider.dart' as provider;

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
    // The list fills its cache region over several frames.
    await tester.pumpAndSettle();

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

  testWidgets('an empty window then a window with only the secret row', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The controller starts empty, then opens a chat with no messages: the
    // real controller adds only the secret row, whose message ID is ''.
    final controller = FakeMessageController(const [], initial: 0);
    await tester.pumpWidget(
      ChatTimelineFixture(
        controller: controller,
        blinkNotifier: BlinkNotifier(tester),
        database: createFixtureDatabase(),
      ),
    );
    await tester.pump();

    controller.value = MessageState(
      conversationId: conversationId,
      top: [
        MessageItem(
          sharedUserIdentityNumber: '',
          status: MessageStatus.read,
          messageId: '',
          conversationId: '',
          userIdentityNumber: '',
          participantUserId: '',
          userId: '',
          type: MessageCategory.secret,
          createdAt: DateTime(2026, 10),
          pinned: false,
          isVerified: false,
          sharedUserIsVerified: false,
        ),
      ],
      isLatest: true,
      isOldest: true,
      refreshKey: Object(),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 11));
  });

  testWidgets('a post of a new window waits for the frame after its rows', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const postIndex = 118;
    final messages = buildMessages(
      120,
      imagePath: '',
      withImages: false,
      postIndexes: {postIndex},
    );
    final controller = FakeMessageController(messages.sublist(0, 60));
    await tester.pumpWidget(
      ChatTimelineFixture(
        controller: controller,
        blinkNotifier: BlinkNotifier(tester),
        database: createFixtureDatabase(),
      ),
    );
    await tester.pumpAndSettle();

    bool built(int index) => find
        .byWidgetPredicate(
          (widget) =>
              widget is MessageItemWidget &&
              widget.message.messageId == messages[index].messageId,
        )
        .evaluate()
        .isNotEmpty;

    // Rows cost more in tests, and the frame budget builds one a frame, so
    // any time spent on other rows defers the post.
    chatCostlyRowWaitMicros = 0;
    addTearDown(() => chatCostlyRowWaitMicros = 1000);
    controller.open(messages.sublist(60), refreshKey: Object());
    await tester.pump();
    await tester.pump();
    expect(built(messages.length - 1), isTrue);
    expect(built(postIndex), isFalse);

    await tester.pumpAndSettle();
    expect(built(postIndex), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 11));
  });

  testWidgets('a new window builds its rows over several frames', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final messages = buildMessages(120, imagePath: '', withImages: false);
    final controller = FakeMessageController(messages.sublist(0, 60));
    await tester.pumpWidget(
      ChatTimelineFixture(
        controller: controller,
        blinkNotifier: BlinkNotifier(tester),
        database: createFixtureDatabase(),
      ),
    );
    await tester.pumpAndSettle();

    controller.open(messages.sublist(60), refreshKey: Object());
    await tester.pump();
    final firstFrame = find.byType(MessageItemWidget).evaluate().length;
    await tester.pumpAndSettle();
    final settled = find.byType(MessageItemWidget).evaluate().length;

    expect(firstFrame, greaterThan(0));
    expect(firstFrame, lessThan(settled));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 11));
  });

  testWidgets('a search keyword rebuilds only the rows that show it', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final messages = buildMessages(30, imagePath: '', withImages: false);
    final controller = FakeMessageController(messages, initial: 30);
    await tester.pumpWidget(
      ChatTimelineFixture(
        controller: controller,
        blinkNotifier: BlinkNotifier(tester),
        database: createFixtureDatabase(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChatHistoryViewport)),
    );
    final rebuilt = <String>[];
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (element.widget is MessageTextWidget) {
        rebuilt.add((element.widget as MessageTextWidget).content);
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    container.read(keywordProvider.notifier).state = 'no match';
    await tester.pump();
    expect(rebuilt, isEmpty);

    container.read(keywordProvider.notifier).state = '会议室';
    await tester.pump();

    expect(rebuilt, isNotEmpty);
    expect(rebuilt.every((content) => content.contains('会议室')), isTrue);

    debugOnRebuildDirtyWidget = null;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 11));
  });

  testWidgets('a global keyword hides the chat search keyword', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final messages = buildMessages(30, imagePath: '', withImages: false);
    final controller = FakeMessageController(messages, initial: 30);
    await tester.pumpWidget(
      ChatTimelineFixture(
        controller: controller,
        blinkNotifier: BlinkNotifier(tester),
        database: createFixtureDatabase(),
      ),
    );
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(ChatHistoryViewport));
    final container = ProviderScope.containerOf(element);

    // Whether the rows that say 收到 highlight it.
    Set<bool> highlighted() => {
      for (final text in tester.widgetList<CustomText>(
        find.byWidgetPredicate((w) => w is CustomText && w.text == '收到'),
      ))
        text.textMatchers!
            .whereType<KeyWordTextMatcher>()
            .single
            .regExp!
            .allMatches('收到')
            .any((match) => match.end > match.start),
    };

    provider.Provider.of<SearchConversationKeywordNotifier>(
      element,
      listen: false,
    ).value = (
      null,
      '收到',
    );
    await tester.pump();
    expect(highlighted(), {true});

    container.read(keywordProvider.notifier).state = 'no match';
    await tester.pump();
    expect(highlighted(), {false});

    container.read(keywordProvider.notifier).state = '';
    await tester.pump();
    expect(highlighted(), {true});

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 11));
  });
}
