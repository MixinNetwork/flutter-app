import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/ui/home/chat/chat_scroll_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  testWidgets(
    'handleScrollNotification preloads after within desktop three-screen window',
    (tester) async {
      final coordinator = ChatScrollCoordinator();
      var loadAfterCount = 0;

      addTearDown(coordinator.dispose);
      final context = await pumpNotificationContext(tester);

      coordinator.handleScrollNotification(
        ScrollUpdateNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 5000,
            pixels: 3500,
            viewportDimension: 600,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1,
          ),
          context: context,
          scrollDelta: 1,
        ),
        messages: const [],
        keysByMessageId: const {},
        loadBefore: () {},
        loadAfter: () => loadAfterCount++,
      );

      expect(loadAfterCount, 1);
    },
  );

  testWidgets(
    'handleScrollNotification preloads before within desktop three-screen window',
    (tester) async {
      final coordinator = ChatScrollCoordinator();
      var loadBeforeCount = 0;

      addTearDown(coordinator.dispose);
      final context = await pumpNotificationContext(tester);

      coordinator.handleScrollNotification(
        ScrollUpdateNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 5000,
            pixels: 1500,
            viewportDimension: 600,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1,
          ),
          context: context,
          scrollDelta: -1,
        ),
        messages: const [],
        keysByMessageId: const {},
        loadBefore: () => loadBeforeCount++,
        loadAfter: () {},
      );

      expect(loadBeforeCount, 1);
    },
  );

  testWidgets('scheduleRestore skips no-op jump after data loads', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(20, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.scrollController.jumpTo(300);
    await tester.pump();

    coordinator.trackingScrollController.jumpCount = 0;
    coordinator
      ..captureViewportState(messages, keysByMessageId)
      ..scheduleRestore(
        messages: messages,
        keysByMessageId: keysByMessageId,
        reset: false,
        isLatest: false,
      );
    await tester.pump();

    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets(
    'handleScrollNotification ignores idle notifications',
    (
      tester,
    ) async {
      final coordinator = ChatScrollCoordinator();
      var loadBeforeCount = 0;
      var loadAfterCount = 0;

      addTearDown(coordinator.dispose);
      final context = await pumpNotificationContext(tester);
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 5000,
        pixels: 3500,
        viewportDimension: 600,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );

      coordinator
        ..handleScrollNotification(
          ScrollUpdateNotification(
            metrics: metrics,
            context: context,
            scrollDelta: 1,
          ),
          messages: const [],
          keysByMessageId: const {},
          loadBefore: () => loadBeforeCount++,
          loadAfter: () => loadAfterCount++,
        )
        ..handleScrollNotification(
          ScrollEndNotification(metrics: metrics, context: context),
          messages: const [],
          keysByMessageId: const {},
          loadBefore: () => loadBeforeCount++,
          loadAfter: () => loadAfterCount++,
        );

      await tester.pump(const Duration(milliseconds: 500));

      expect(loadBeforeCount, 0);
      expect(loadAfterCount, 1);
    },
  );

  testWidgets('scheduleRestore does not jump while user is scrolling', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(20, testMessage);
    final nextMessages = [testMessage(100), ...messages];
    final keysByMessageId = {
      for (final message in nextMessages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.scrollController.jumpTo(300);
    await tester.pump();
    coordinator.captureViewportState(messages, keysByMessageId);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(
      coordinator.scrollController.position.isScrollingNotifier.value,
      true,
    );

    await pumpScrollableMessages(
      tester,
      coordinator,
      nextMessages,
      keysByMessageId,
    );
    coordinator.trackingScrollController.jumpCount = 0;
    coordinator.scheduleRestore(
      messages: nextMessages,
      keysByMessageId: keysByMessageId,
      reset: false,
      isLatest: false,
    );
    await tester.pump();
    await gesture.up();

    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets('scheduleRestore does not jump for non-pinned paging updates', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(20, testMessage);
    final nextMessages = [testMessage(-1), ...messages];
    final keysByMessageId = {
      for (final message in nextMessages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.scrollController.jumpTo(800);
    await tester.pump();
    coordinator.captureViewportState(messages, keysByMessageId);

    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      nextMessages,
      keysByMessageId,
    );
    coordinator.trackingScrollController.jumpCount = 0;
    coordinator.scheduleRestore(
      messages: nextMessages,
      keysByMessageId: keysByMessageId,
      reset: false,
      isLatest: false,
    );
    await tester.pump();

    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets('scheduleRestore animates explicit message jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(20, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };
    final targetMessageId = messages[8].messageId;

    addTearDown(coordinator.dispose);
    await pumpScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.trackingScrollController.jumpCount = 0;

    coordinator
      ..nextAnimatedRestoreMessageId = targetMessageId
      ..scheduleRestore(
        messages: messages,
        keysByMessageId: keysByMessageId,
        reset: true,
        isLatest: false,
        centerMessageId: targetMessageId,
      );
    await tester.pump();

    expect(coordinator.trackingScrollController.animateCount, 1);
    expect(
      coordinator.trackingScrollController.lastDuration,
      const Duration(milliseconds: 300),
    );
    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets('scheduleRestore does not stage explicit message jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };
    final targetMessageId = messages[18].messageId;

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    coordinator
      ..nextAnimatedRestoreMessageId = targetMessageId
      ..scheduleRestore(
        messages: messages,
        keysByMessageId: keysByMessageId,
        reset: true,
        isLatest: false,
        centerMessageId: targetMessageId,
      );
    await tester.pump();

    expect(coordinator.trackingScrollController.animateCount, 1);
    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets(
    'scheduleRestore starts older explicit jumps after the target',
    (tester) async {
      final coordinator = TrackingChatScrollCoordinator();
      final messages = List.generate(30, testMessage);
      final keysByMessageId = {
        for (final message in messages) message.messageId: GlobalKey(),
      };
      final targetMessageId = messages[18].messageId;

      addTearDown(coordinator.dispose);
      await pumpFullyBuiltScrollableMessages(
        tester,
        coordinator,
        messages,
        keysByMessageId,
      );
      coordinator.trackingScrollController
        ..animateCount = 0
        ..jumpCount = 0
        ..jumpOffsets.clear()
        ..animateOffsets.clear();

      coordinator
        ..animateNextMessageRestore(
          targetMessageId,
          direction: ChatScrollRestoreDirection.towardOlder,
        )
        ..scheduleRestore(
          messages: messages,
          keysByMessageId: keysByMessageId,
          reset: true,
          isLatest: false,
          centerMessageId: targetMessageId,
        );
      await tester.pump();

      expect(coordinator.trackingScrollController.animateCount, 1);
      expect(coordinator.trackingScrollController.jumpCount, 1);
      expect(
        coordinator.trackingScrollController.jumpOffsets.single,
        greaterThan(coordinator.trackingScrollController.animateOffsets.single),
      );
    },
  );

  testWidgets('scrollToBottom stages distant animated jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    await coordinator.scrollToBottom(animated: true);

    expect(coordinator.trackingScrollController.animateCount, 1);
    expect(coordinator.trackingScrollController.jumpCount, 1);
  });

  testWidgets('scrollToBottomIfInLoadedWindow animates nearby latest jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.scrollController.jumpTo(
      coordinator.scrollController.position.maxScrollExtent - 360,
    );
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    final handled = await coordinator.scrollToBottomIfInLoadedWindow(
      animated: true,
    );

    expect(handled, true);
    expect(coordinator.trackingScrollController.animateCount, 1);
    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets('scrollToBottomIfInLoadedWindow rejects far latest jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    final handled = await coordinator.scrollToBottomIfInLoadedWindow(
      animated: true,
    );

    expect(handled, false);
    expect(coordinator.trackingScrollController.animateCount, 0);
    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets('scrollToMessageIfInLoadedWindow animates nearby target jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };
    final targetMessageId = messages[4].messageId;

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.updateMessages(messages, keysByMessageId);
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    final handled = await coordinator.scrollToMessageIfInLoadedWindow(
      targetMessageId,
      animated: true,
    );

    expect(handled, true);
    expect(coordinator.trackingScrollController.animateCount, 1);
    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets(
    'scrollToMessageIfInLoadedWindow does not stage two-screen target jumps',
    (tester) async {
      final coordinator = TrackingChatScrollCoordinator();
      final messages = List.generate(40, testMessage);
      final keysByMessageId = {
        for (final message in messages) message.messageId: GlobalKey(),
      };
      final targetMessageId = messages[14].messageId;

      addTearDown(coordinator.dispose);
      await pumpFullyBuiltScrollableMessages(
        tester,
        coordinator,
        messages,
        keysByMessageId,
        viewportHeight: 600,
      );
      coordinator.updateMessages(messages, keysByMessageId);
      coordinator.trackingScrollController
        ..animateCount = 0
        ..jumpCount = 0;

      final handled = await coordinator.scrollToMessageIfInLoadedWindow(
        targetMessageId,
        animated: true,
      );

      expect(handled, true);
      expect(coordinator.trackingScrollController.animateCount, 1);
      expect(coordinator.trackingScrollController.jumpCount, 0);
    },
  );

  testWidgets('handleScrollNotification ignores programmatic jump animations', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };
    final targetMessageId = messages[4].messageId;
    var loadAfterCount = 0;

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.updateMessages(messages, keysByMessageId);
    final animationCompleter = Completer<void>();
    coordinator.trackingScrollController.animationCompleter =
        animationCompleter;

    final jumpFuture = coordinator.scrollToMessageIfInLoadedWindow(
      targetMessageId,
      animated: true,
    );
    await tester.pump();

    coordinator.handleScrollNotification(
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 5000,
          pixels: 4600,
          viewportDimension: 600,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1,
        ),
        context: tester.element(find.byType(SingleChildScrollView)),
        scrollDelta: 1,
      ),
      messages: messages,
      keysByMessageId: keysByMessageId,
      loadBefore: () {},
      loadAfter: () => loadAfterCount++,
    );

    animationCompleter.complete();
    await jumpFuture;

    expect(loadAfterCount, 0);
  });

  testWidgets(
    'scrollToMessageIfInLoadedWindow does not estimate unbuilt targets',
    (
      tester,
    ) async {
      final coordinator = TrackingChatScrollCoordinator();
      final messages = List.generate(100, testMessage);
      final keysByMessageId = {
        for (final message in messages) message.messageId: GlobalKey(),
      };
      final targetMessageId = messages[26].messageId;

      addTearDown(coordinator.dispose);
      await pumpScrollableMessages(
        tester,
        coordinator,
        messages,
        keysByMessageId,
        cacheExtent: 0,
        itemHeight: 30,
        viewportHeight: 500,
      );
      coordinator.updateMessages(messages, keysByMessageId);
      expect(keysByMessageId[targetMessageId]?.currentContext, isNull);
      coordinator.trackingScrollController
        ..animateCount = 0
        ..jumpCount = 0;

      final handled = await coordinator.scrollToMessageIfInLoadedWindow(
        targetMessageId,
        animated: true,
      );

      expect(handled, false);
      expect(coordinator.trackingScrollController.animateCount, 0);
      expect(coordinator.trackingScrollController.jumpCount, 0);
    },
  );

  testWidgets(
    'scrollToMessageIfInLoadedWindow animates repeated target jumps',
    (
      tester,
    ) async {
      final coordinator = TrackingChatScrollCoordinator();
      final messages = List.generate(30, testMessage);
      final keysByMessageId = {
        for (final message in messages) message.messageId: GlobalKey(),
      };
      final targetMessageId = messages[4].messageId;

      addTearDown(coordinator.dispose);
      await pumpFullyBuiltScrollableMessages(
        tester,
        coordinator,
        messages,
        keysByMessageId,
      );
      coordinator.updateMessages(messages, keysByMessageId);
      coordinator.trackingScrollController
        ..animateCount = 0
        ..jumpCount = 0;

      final handled = await coordinator.scrollToMessageIfInLoadedWindow(
        targetMessageId,
        animated: true,
      );
      final targetOffset = coordinator.trackingScrollController.lastOffset;
      coordinator.trackingScrollController
        ..jumpTo(targetOffset!)
        ..animateCount = 0
        ..jumpCount = 0;

      final secondHandled = await coordinator.scrollToMessageIfInLoadedWindow(
        targetMessageId,
        animated: true,
      );

      expect(handled, true);
      expect(secondHandled, true);
      expect(coordinator.trackingScrollController.animateCount, 1);
      expect(coordinator.trackingScrollController.jumpCount, 0);
    },
  );

  testWidgets('scrollToMessageIfInLoadedWindow rejects far target jumps', (
    tester,
  ) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };
    final targetMessageId = messages.first.messageId;

    addTearDown(coordinator.dispose);
    await pumpFullyBuiltScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.scrollController.jumpTo(
      coordinator.scrollController.position.maxScrollExtent,
    );
    coordinator.updateMessages(messages, keysByMessageId);
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    final handled = await coordinator.scrollToMessageIfInLoadedWindow(
      targetMessageId,
      animated: true,
    );

    expect(handled, false);
    expect(coordinator.trackingScrollController.animateCount, 0);
    expect(coordinator.trackingScrollController.jumpCount, 0);
  });

  testWidgets('scheduleRestore animates next latest restore', (tester) async {
    final coordinator = TrackingChatScrollCoordinator();
    final messages = List.generate(30, testMessage);
    final keysByMessageId = {
      for (final message in messages) message.messageId: GlobalKey(),
    };

    addTearDown(coordinator.dispose);
    await pumpScrollableMessages(
      tester,
      coordinator,
      messages,
      keysByMessageId,
    );
    coordinator.trackingScrollController
      ..animateCount = 0
      ..jumpCount = 0;

    coordinator
      ..animateNextRestore()
      ..scheduleRestore(
        messages: messages,
        keysByMessageId: keysByMessageId,
        reset: true,
        isLatest: true,
      );
    await tester.pump();

    expect(coordinator.trackingScrollController.animateCount, 1);
  });
}

class TrackingChatScrollCoordinator extends ChatScrollCoordinator {
  TrackingChatScrollCoordinator()
    : _scrollController = TrackingScrollController();

  @override
  TrackingScrollController get scrollController => _scrollController;

  TrackingScrollController get trackingScrollController => _scrollController;

  final TrackingScrollController _scrollController;
}

class TrackingScrollController extends ScrollController {
  int jumpCount = 0;
  int animateCount = 0;
  double? lastOffset;
  Duration? lastDuration;
  final jumpOffsets = <double>[];
  final animateOffsets = <double>[];
  Completer<void>? animationCompleter;

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    animateCount++;
    lastOffset = offset;
    lastDuration = duration;
    animateOffsets.add(offset);
    return animationCompleter?.future ?? Future<void>.value();
  }

  @override
  void jumpTo(double value) {
    jumpCount++;
    lastOffset = value;
    jumpOffsets.add(value);
    super.jumpTo(value);
  }
}

Future<void> pumpScrollableMessages(
  WidgetTester tester,
  ChatScrollCoordinator coordinator,
  List<MessageItem> messages,
  Map<String, GlobalKey> keysByMessageId, {
  double? cacheExtent,
  double itemHeight = 80,
  double viewportHeight = 240,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 320,
        height: viewportHeight,
        child: CustomScrollView(
          key: coordinator.viewportKey,
          controller: coordinator.scrollController,
          scrollCacheExtent: cacheExtent == null
              ? null
              : ScrollCacheExtent.pixels(cacheExtent),
          slivers: [
            SliverList.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) => SizedBox(
                key: keysByMessageId[messages[index].messageId],
                height: itemHeight,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pumpFullyBuiltScrollableMessages(
  WidgetTester tester,
  ChatScrollCoordinator coordinator,
  List<MessageItem> messages,
  Map<String, GlobalKey> keysByMessageId, {
  double viewportHeight = 240,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 320,
        height: viewportHeight,
        child: SingleChildScrollView(
          key: coordinator.viewportKey,
          controller: coordinator.scrollController,
          child: Column(
            children: [
              for (final message in messages)
                SizedBox(
                  key: keysByMessageId[message.messageId],
                  height: 80,
                ),
            ],
          ),
        ),
      ),
    ),
  );
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

Future<BuildContext> pumpNotificationContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (builderContext) {
          context = builderContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return context;
}
