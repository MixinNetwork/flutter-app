import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/quote_message_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_app/widgets/message/message_action_policy.dart';
import 'package:flutter_app/widgets/message/message_bubble.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart' as provider;

void main() {
  test('MessageRows links top tail to first bottom row without center', () {
    final rows = MessageRows.from(
      top: [
        testMessage('top', userId: 'same'),
      ],
      center: null,
      bottom: [
        testMessage('bottom-first', userId: 'same'),
        testMessage('bottom-last', userId: 'other'),
      ],
    );

    expect(rows.top.single.sameUserNext, isTrue);
    expect(rows.bottom.first.sameUserPrev, isTrue);
  });

  test('MessageActionPolicy keeps chat-only actions out of pinned views', () {
    final message = testMessage('1');

    final chatPolicy = MessageActionPolicy(
      message: message,
      isTranscriptPage: false,
      isPinnedPage: false,
      role: Object(),
    );
    expect(chatPolicy.canReply, isTrue);
    expect(chatPolicy.canPin, isTrue);
    expect(chatPolicy.canDelete, isTrue);

    final pinnedPolicy = MessageActionPolicy(
      message: message,
      isTranscriptPage: false,
      isPinnedPage: true,
      role: Object(),
    );
    expect(pinnedPolicy.canReply, isFalse);
    expect(pinnedPolicy.canDelete, isFalse);
  });

  testWidgets('MessageContext updates const children through inherited state', (
    tester,
  ) async {
    final message = ValueNotifier(testMessage('1'));
    addTearDown(message.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<MessageItem>(
          valueListenable: message,
          builder: (context, value, child) => MessageContext.fromMessageItem(
            message: value,
            child: child!,
          ),
          child: const _MessageIdText(),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    message.value = testMessage('2');
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('MessageBubble stretches short quote to message width', (
    tester,
  ) async {
    const bodyKey = ValueKey('body');
    final message = testMessage(
      '1',
      quoteId: 'quoted',
      quoteContent: _quoteContent,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => DatabaseOpener()),
          mentionCacheProvider.overrideWithValue(MentionCache(null)),
          settingProvider.overrideWith((ref) => SettingChangeNotifier()),
        ],
        child: MaterialApp(
          home: BrightnessData(
            value: 0,
            brightnessThemeData: lightBrightnessThemeData,
            child: Align(
              alignment: Alignment.topLeft,
              child: MessageContext.fromMessageItem(
                message: message,
                child: const SizedBox(
                  width: 400,
                  child: MessageBubble(
                    child: SizedBox(key: bodyKey, width: 260, height: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final quoteWidth = tester.getSize(find.byType(QuoteMessage)).width;
    final bodyWidth = tester.getSize(find.byKey(bodyKey)).width;

    expect(quoteWidth, greaterThanOrEqualTo(bodyWidth));
  });

  testWidgets('current user blink is visible enough', (tester) async {
    final notifier = BlinkNotifier(tester)..blinkByMessageId('1');

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: notifier,
        child: MessageContext.fromMessageItem(
          message: testMessage(
            '1',
            userId: 'me',
            relationship: UserRelationship.me,
          ),
          child: const MessageBubble(child: SizedBox(width: 80, height: 20)),
        ),
      ),
    );
    await tester.pump();

    final highlightPainters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where(
          (paint) =>
              paint.foregroundPainter.runtimeType.toString() ==
              '_MessageBubbleHighlightPainter',
        )
        .toList();
    final opacity = messageHighlightOpacityForTesting(
      tester.element(find.byType(MessageBubble)),
      currentUser: true,
      media: false,
    );

    expect(highlightPainters, isNotEmpty);
    expect(opacity, greaterThanOrEqualTo(0.16));

    await tester.pumpWidget(const SizedBox.shrink());
    notifier.dispose();
  });

  testWidgets('double tapping a message starts a quote reply', (tester) async {
    final blinkNotifier = BlinkNotifier(tester);

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: blinkNotifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: const MessageQuickReplyDetector(
            child: MessageBubble(child: SizedBox(width: 80, height: 20)),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MessageQuickReplyDetector)),
    );
    expect(container.read(quoteMessageProvider), isNull);

    await tester.tap(find.byType(MessageQuickReplyDetector));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(MessageQuickReplyDetector));
    await tester.pump();

    expect(container.read(quoteMessageProvider)?.messageId, '1');

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    blinkNotifier.dispose();
  });

  testWidgets('blink keeps bubble content mounted', (tester) async {
    final notifier = BlinkNotifier(tester);
    final mountCount = ValueNotifier(0);
    addTearDown(mountCount.dispose);

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: notifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: MessageBubble(child: _MountCounter(count: mountCount)),
        ),
      ),
    );
    await tester.pump();

    expect(mountCount.value, 1);

    notifier.blinkByMessageId('1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(mountCount.value, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    notifier.dispose();
  });

  test('mention read marker only fires for fully visible unread mentions', () {
    expect(shouldMarkMentionRead(false, 1), isTrue);
    expect(shouldMarkMentionRead(false, 0.99), isFalse);
    expect(shouldMarkMentionRead(true, 1), isFalse);
    expect(shouldMarkMentionRead(null, 1), isFalse);
  });

  testWidgets(
    'prewarmed mention provider renders display name on first frame',
    (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWith((ref) => DatabaseOpener()),
          settingProvider.overrideWith((ref) => SettingChangeNotifier()),
        ],
      );
      addTearDown(container.dispose);

      container.read(mentionCacheProvider).cacheUsers([
        const User(userId: 'user-1', identityNumber: '7001', fullName: 'Alice'),
      ]);
      await container.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BrightnessData(
              value: 0,
              brightnessThemeData: lightBrightnessThemeData,
              child: _MentionTextHarness(content: 'hello @7001'),
            ),
          ),
        ),
      );

      expect(_richTextPlainText(tester), isNot(contains('@7001')));
      expect(_richTextPlainText(tester), contains('@Alice'));
    },
  );
}

class _MessageIdText extends HookWidget {
  const _MessageIdText();

  @override
  Widget build(BuildContext context) => Text(
    useMessageConverter(converter: (message) => message.messageId),
  );
}

class _MountCounter extends StatefulWidget {
  const _MountCounter({required this.count});

  final ValueNotifier<int> count;

  @override
  State<_MountCounter> createState() => _MountCounterState();
}

class _MountCounterState extends State<_MountCounter> {
  @override
  void initState() {
    super.initState();
    widget.count.value++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 80, height: 20);
}

class _MentionTextHarness extends HookConsumerWidget {
  const _MentionTextHarness({required this.content});

  final String content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionCache = ref.read(mentionCacheProvider);
    final mentionMap = useMemoizedFuture(
      () => mentionCache.checkMentionCache({content}),
      mentionCache.mentionCache(content),
      keys: [content],
    ).requireData;

    return CustomText(
      content,
      textMatchers: [
        MentionTextMatcher(context, mentionMap),
      ],
    );
  }
}

String _richTextPlainText(WidgetTester tester) => tester
    .widgetList<RichText>(
      find.byWidgetPredicate((widget) => widget is RichText),
    )
    .map((widget) => widget.text.toPlainText())
    .join('\n');

MessageItem testMessage(
  String id, {
  String userId = 'user',
  UserRelationship relationship = UserRelationship.friend,
  String? quoteId,
  String? quoteContent,
  bool? mentionRead,
}) => MessageItem(
  messageId: id,
  conversationId: 'conversation',
  type: 'PLAIN_TEXT',
  content: 'body',
  createdAt: DateTime(2026),
  status: MessageStatus.read,
  userId: userId,
  relationship: relationship,
  userIdentityNumber: '0',
  isVerified: false,
  sharedUserIsVerified: false,
  quoteId: quoteId,
  quoteContent: quoteContent,
  mentionRead: mentionRead,
  pinned: false,
);

const _quoteContent =
    '{"message_id":"quoted","conversation_id":"conversation",'
    '"user_id":"00000000-0000-4000-8000-000000000001",'
    '"user_full_name":"KC","user_identity_number":"1","type":"PLAIN_TEXT",'
    '"content":"q","createdAt":1767225600000,"status":"READ"}';

class _MessageTestScope extends StatelessWidget {
  const _MessageTestScope({required this.child, this.blinkNotifier});

  final Widget child;
  final BlinkNotifier? blinkNotifier;

  @override
  Widget build(BuildContext context) {
    final blinkNotifier = this.blinkNotifier;
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWith((ref) => DatabaseOpener()),
        mentionCacheProvider.overrideWithValue(MentionCache(null)),
        settingProvider.overrideWith((ref) => SettingChangeNotifier()),
      ],
      child: MaterialApp(
        home: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: Align(
            alignment: Alignment.topLeft,
            child: blinkNotifier == null
                ? child
                : provider.ChangeNotifierProvider<BlinkNotifier>.value(
                    value: blinkNotifier,
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
