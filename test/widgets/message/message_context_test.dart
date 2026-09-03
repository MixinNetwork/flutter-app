import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/mixin_database.dart' hide Offset;
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/ui/home/notifier/blink_notifier.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/message_selection_provider.dart';
import 'package:flutter_app/ui/provider/quote_message_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/utils/app_lifecycle.dart';
import 'package:flutter_app/utils/hook.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_app/widgets/message/item/action/action_data.dart';
import 'package:flutter_app/widgets/message/item/action/action_message.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';
import 'package:flutter_app/widgets/message/item/text/selectable.dart'
    as message_selectable;
import 'package:flutter_app/widgets/message/item/text/text_message.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_app/widgets/message/message_action_policy.dart';
import 'package:flutter_app/widgets/message/message_bubble.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart' hide User;
import 'package:provider/provider.dart' as provider;
import 'package:visibility_detector/visibility_detector.dart';

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
      role: ParticipantRole.owner,
    );
    expect(chatPolicy.canReply, isTrue);
    expect(chatPolicy.canPin, isTrue);
    expect(chatPolicy.canDelete, isTrue);

    final pinnedPolicy = MessageActionPolicy(
      message: message,
      isTranscriptPage: false,
      isPinnedPage: true,
      role: ParticipantRole.owner,
    );
    expect(pinnedPolicy.canReply, isFalse);
    expect(pinnedPolicy.canDelete, isFalse);
  });

  test(
    'MessageActionPolicy allows recalling peer messages in direct chats',
    () {
      final policy = MessageActionPolicy(
        message: testMessage(
          '1',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          conversionCategory: ConversationCategory.contact,
        ),
        isTranscriptPage: false,
        isPinnedPage: false,
        role: ParticipantRole.owner,
      );

      expect(policy.canRecall, isTrue);
    },
  );

  test('MessageActionPolicy enforces the group recall role hierarchy', () {
    MessageActionPolicy policy(
      ParticipantRole? actorRole,
      ParticipantRole? senderRole, {
      String? senderParticipantId = 'member',
      String senderUserId = 'sender',
      String conversationOwnerId = 'owner',
    }) => MessageActionPolicy(
      message: testMessage(
        '1',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        conversionCategory: ConversationCategory.group,
        conversationOwnerId: conversationOwnerId,
        senderParticipantId: senderParticipantId,
        senderRole: senderRole,
        userId: senderUserId,
      ),
      isTranscriptPage: false,
      isPinnedPage: false,
      role: actorRole,
    );

    expect(
      policy(ParticipantRole.owner, ParticipantRole.admin).canRecall,
      true,
    );
    expect(policy(ParticipantRole.admin, null).canRecall, true);
    expect(
      policy(ParticipantRole.admin, ParticipantRole.admin).canRecall,
      false,
    );
    expect(
      policy(ParticipantRole.admin, ParticipantRole.owner).canRecall,
      false,
    );
    expect(
      policy(
        ParticipantRole.admin,
        null,
        senderUserId: 'owner',
      ).canRecall,
      false,
    );
    expect(
      policy(
        ParticipantRole.admin,
        null,
        senderParticipantId: null,
      ).canRecall,
      false,
    );
    expect(policy(null, null).canRecall, false);
  });

  test('MessageActionPolicy keeps recall message constraints', () {
    MessageActionPolicy policy(MessageItem message) => MessageActionPolicy(
      message: message,
      isTranscriptPage: false,
      isPinnedPage: false,
      role: ParticipantRole.owner,
    );

    expect(
      policy(
        testMessage(
          'valid',
          createdAt: DateTime.now().subtract(const Duration(days: 29)),
          relationship: UserRelationship.me,
        ),
      ).canRecall,
      true,
    );
    expect(
      policy(
        testMessage(
          'expired',
          createdAt: DateTime.now().subtract(
            const Duration(days: 30, seconds: 1),
          ),
          relationship: UserRelationship.me,
        ),
      ).canRecall,
      false,
    );
    expect(
      policy(
        testMessage(
          'sending',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          relationship: UserRelationship.me,
          status: MessageStatus.sending,
        ),
      ).canRecall,
      false,
    );
    expect(
      policy(
        testMessage(
          'unsupported',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          relationship: UserRelationship.me,
          type: MessageCategory.systemUser,
        ),
      ).canRecall,
      false,
    );
  });

  test('MessageSelectionNotifier applies recall roles to added messages', () {
    final selection = MessageSelectionNotifier(role: ParticipantRole.admin);
    addTearDown(selection.dispose);
    final createdAt = DateTime.now().subtract(const Duration(days: 1));

    selection
      ..selectMessage(
        testMessage(
          '1',
          createdAt: createdAt,
          conversionCategory: ConversationCategory.group,
          senderParticipantId: 'member-1',
        ),
      )
      ..toggleSelection(
        testMessage(
          '2',
          createdAt: createdAt,
          conversionCategory: ConversationCategory.group,
          senderParticipantId: 'member-2',
        ),
      );

    expect(selection.canRecall, isTrue);
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

  testWidgets(
    'inactive mutes message ticker while sibling scroll still animates',
    (tester) async {
      final previousAppActive = appActiveListener.value;
      final visibilityController = VisibilityDetectorController.instance;
      final previousUpdateInterval = visibilityController.updateInterval;
      addTearDown(
        () => visibilityController.updateInterval = previousUpdateInterval,
      );
      visibilityController.updateInterval = Duration.zero;
      addTearDown(() => appActiveListener.value = previousAppActive);
      initAppLifecycleObserver();
      appActiveListener.value = true;
      final message = testMessage('ticker', type: MessageCategory.secret);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        _MessageTestScope(
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              Localization.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            child: SizedBox(
              width: 600,
              height: 600,
              child: Column(
                children: [
                  SizedBox(
                    height: 100,
                    child: MessageItemWidget(
                      message: message,
                      row: MessageRowModel(message: message, prev: message),
                      isGroupOrBotGroupConversation: false,
                      enableShowAvatar: false,
                      blink: false,
                      showUnreadBar: false,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: List<Widget>.generate(
                        40,
                        (index) => SizedBox(
                          height: 40,
                          child: Text(index.toString()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(MessageContext), findsOneWidget);
      expect(scrollController.position.maxScrollExtent, greaterThan(0));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
        TickerMode.valuesOf(
          tester.element(find.byType(MessageContext)),
        ).enabled,
        isFalse,
      );
      expect(
        TickerMode.valuesOf(tester.element(find.byType(Scrollable))).enabled,
        isTrue,
      );

      final scrollAnimation = scrollController.animateTo(
        400,
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(scrollController.offset, greaterThan(0));
      await scrollAnimation;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(
        TickerMode.valuesOf(
          tester.element(find.byType(MessageContext)),
        ).enabled,
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
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

    final highlightPainters = _highlightPainters(tester);
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

  testWidgets(
    'showBubble false wrapper does not blink without a bubble surface',
    (
      tester,
    ) async {
      final notifier = BlinkNotifier(tester)..blinkByMessageId('1');

      await tester.pumpWidget(
        _MessageTestScope(
          blinkNotifier: notifier,
          child: MessageContext.fromMessageItem(
            message: testMessage('1'),
            child: const MessageBubble(
              showBubble: false,
              padding: EdgeInsets.zero,
              child: SizedBox(width: 80, height: 20),
            ),
          ),
        ),
      );
      await tester.pump();

      final highlightPainters = _highlightPainters(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      notifier.dispose();

      expect(highlightPainters, isEmpty);
    },
  );

  testWidgets('action buttons blink their bubble surface', (tester) async {
    final notifier = BlinkNotifier(tester)..blinkByMessageId('1');

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: notifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: Center(
            child: ActionMessageButton(
              action: ActionData('Open', '#000000', 'https://example.com'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final highlightPainters = _highlightPainters(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    notifier.dispose();

    expect(highlightPainters, hasLength(1));
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

  testWidgets('double tapping tappable bubble content starts a quote reply', (
    tester,
  ) async {
    const bodyKey = ValueKey('tappable-body');
    final blinkNotifier = BlinkNotifier(tester);

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: blinkNotifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: MessageQuickReplyDetector(
            child: MessageBubble(
              child: GestureDetector(
                key: bodyKey,
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: const SizedBox(width: 80, height: 20),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MessageQuickReplyDetector)),
    );
    expect(container.read(quoteMessageProvider), isNull);

    await tester.tap(find.byKey(bodyKey));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(bodyKey));
    await tester.pump();

    expect(container.read(quoteMessageProvider)?.messageId, '1');

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    blinkNotifier.dispose();
  });

  testWidgets('double tapping selectable text does not start a quote reply', (
    tester,
  ) async {
    final blinkNotifier = BlinkNotifier(tester);
    final selectedText = ValueNotifier<String?>(null);
    final focusNode = FocusNode(debugLabel: 'test_selection_focus');
    addTearDown(focusNode.dispose);
    addTearDown(selectedText.dispose);

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: blinkNotifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: MessageQuickReplyDetector(
            child: MessageBubble(
              child: message_selectable.SelectableRegion(
                focusNode: focusNode,
                selectionControls: desktopTextSelectionHandleControls,
                contextMenuBuilder: (context, state) => const SizedBox(),
                onSelectionChanged: (content) =>
                    selectedText.value = content?.plainText,
                child: const CustomText('hello world'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MessageQuickReplyDetector)),
    );

    final text = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText() == 'hello world',
    );

    final firstWordPosition =
        tester.getRect(text).centerLeft + const Offset(12, 0);

    await tester.tapAt(firstWordPosition, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(firstWordPosition, kind: PointerDeviceKind.mouse);
    await tester.pump();

    expect(container.read(quoteMessageProvider), isNull);
    expect(selectedText.value, 'hello');

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    blinkNotifier.dispose();
  });

  testWidgets('double tapping outside selectable text starts a quote reply', (
    tester,
  ) async {
    const outsideTextKey = ValueKey('outside-selectable-text');
    final blinkNotifier = BlinkNotifier(tester);
    final focusNode = FocusNode(debugLabel: 'test_selection_focus');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: blinkNotifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: MessageQuickReplyDetector(
            child: MessageBubble(
              child: MessageSelectionArea(
                focusNode: focusNode,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText('hello world'),
                    SizedBox(
                      key: outsideTextKey,
                      width: 48,
                      height: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MessageQuickReplyDetector)),
    );
    expect(container.read(quoteMessageProvider), isNull);

    final outsideTextPosition = tester.getCenter(find.byKey(outsideTextKey));

    await tester.tapAt(outsideTextPosition, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(outsideTextPosition, kind: PointerDeviceKind.mouse);
    await tester.pump();

    expect(container.read(quoteMessageProvider)?.messageId, '1');

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(const SizedBox.shrink());
    blinkNotifier.dispose();
  });

  testWidgets('double tapping selectable line end starts a quote reply', (
    tester,
  ) async {
    final blinkNotifier = BlinkNotifier(tester);

    await tester.pumpWidget(
      _MessageTestScope(
        blinkNotifier: blinkNotifier,
        child: MessageContext.fromMessageItem(
          message: testMessage('1'),
          child: const MessageQuickReplyDetector(
            child: MessageBubble(
              child: MessageSelectionArea(
                child: SizedBox(
                  width: 240,
                  child: CustomText('first line\nx'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MessageQuickReplyDetector)),
    );
    final text = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText() == 'first line\nx',
    );
    final textRect = tester.getRect(text);
    final secondLineEnd = Offset(
      textRect.right - 8,
      textRect.top + textRect.height * 0.75,
    );

    await tester.tapAt(secondLineEnd, kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(secondLineEnd, kind: PointerDeviceKind.mouse);
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

List<CustomPaint> _highlightPainters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .where(
      (paint) =>
          paint.foregroundPainter.runtimeType.toString() ==
          '_MessageBubbleHighlightPainter',
    )
    .toList();

MessageItem testMessage(
  String id, {
  String type = MessageCategory.plainText,
  String userId = 'user',
  UserRelationship relationship = UserRelationship.friend,
  MessageStatus status = MessageStatus.read,
  DateTime? createdAt,
  ConversationCategory? conversionCategory,
  String? conversationOwnerId,
  String? senderParticipantId,
  ParticipantRole? senderRole,
  String? quoteId,
  String? quoteContent,
  bool? mentionRead,
}) => MessageItem(
  messageId: id,
  conversationId: 'conversation',
  type: type,
  content: 'body',
  createdAt: createdAt ?? DateTime(2026),
  status: status,
  userId: userId,
  relationship: relationship,
  conversionCategory: conversionCategory,
  conversationOwnerId: conversationOwnerId,
  senderParticipantId: senderParticipantId,
  senderRole: senderRole,
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
