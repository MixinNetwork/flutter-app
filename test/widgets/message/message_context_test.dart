import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/mention_cache_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/message/item/quote_message.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_app/widgets/message/message_action_policy.dart';
import 'package:flutter_app/widgets/message/message_bubble.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

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
}

class _MessageIdText extends HookWidget {
  const _MessageIdText();

  @override
  Widget build(BuildContext context) => Text(
    useMessageConverter(converter: (message) => message.messageId),
  );
}

MessageItem testMessage(
  String id, {
  String userId = 'user',
  String? quoteId,
  String? quoteContent,
}) => MessageItem(
  messageId: id,
  conversationId: 'conversation',
  type: 'PLAIN_TEXT',
  content: 'body',
  createdAt: DateTime(2026),
  status: MessageStatus.read,
  userId: userId,
  userIdentityNumber: '0',
  isVerified: false,
  sharedUserIsVerified: false,
  quoteId: quoteId,
  quoteContent: quoteContent,
  pinned: false,
);

const _quoteContent =
    '{"message_id":"quoted","conversation_id":"conversation",'
    '"user_id":"00000000-0000-4000-8000-000000000001",'
    '"user_full_name":"KC","user_identity_number":"1","type":"PLAIN_TEXT",'
    '"content":"q","createdAt":1767225600000,"status":"READ"}';
