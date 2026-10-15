import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/ui/home/chat/chat_history_viewport.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/home/notifier/chat_side_notifier.dart';
import 'package:flutter_app/ui/provider/keyword_provider.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_app/widgets/message/item/text/text_message.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  testWidgets(
    'a long message shows its links once the background detection ends',
    (tester) async {
      tester.view
        ..physicalSize = const Size(1000, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      String content(String path) =>
          '${List.filled(50, '今天下午三点讨论发布计划，大家记得带上电脑。').join()} '
          'see https://mixin.one/blog/$path for details.';
      final base = buildMessages(1, imagePath: '', withImages: false).single;
      MessageItem message(String text) => MessageItem(
        messageId: base.messageId,
        conversationId: base.conversationId,
        type: base.type,
        content: text,
        createdAt: base.createdAt,
        status: base.status,
        userId: base.userId,
        userFullName: base.userFullName,
        userIdentityNumber: base.userIdentityNumber,
        isVerified: false,
        sharedUserIsVerified: false,
        pinned: false,
        conversionCategory: base.conversionCategory,
      );

      Future<(bool, Size)> show(String text) async {
        await tester.pumpWidget(
          ChatTimelineFixture(
            key: UniqueKey(),
            controller: FakeMessageController([message(text)], initial: 1),
            blinkNotifier: BlinkNotifier(tester),
            database: createFixtureDatabase(),
          ),
        );
        await tester.pump();
        var hasLink = false;
        for (final rich in tester.widgetList<RichText>(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('blog'),
          ),
        )) {
          rich.text.visitChildren((span) {
            if (span is TextSpan && span.recognizer != null) hasLink = true;
            return !hasLink;
          });
        }
        return (hasLink, tester.getSize(find.byType(MessageItemWidget)));
      }

      // Before any widget mounts: plugins start async work once they do.
      await tester.runAsync(() => prepareDarwinLinkRanges(content('bbb')));

      final (pendingLink, pendingSize) = await show(content('aaa'));
      expect(pendingLink, isFalse);

      final (readyLink, readySize) = await show(content('bbb'));
      expect(readyLink, isTrue);
      expect(readySize, pendingSize);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 11));
    },
    skip: !Platform.isMacOS,
  );
}
