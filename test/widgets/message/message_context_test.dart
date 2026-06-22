import 'package:flutter/material.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/widgets/message/message.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

class _MessageIdText extends HookWidget {
  const _MessageIdText();

  @override
  Widget build(BuildContext context) => Text(
    useMessageConverter(converter: (message) => message.messageId),
  );
}

MessageItem testMessage(String id, {String userId = 'user'}) => MessageItem(
  messageId: id,
  conversationId: 'conversation',
  type: 'PLAIN_TEXT',
  createdAt: DateTime(2026),
  status: MessageStatus.read,
  userId: userId,
  userIdentityNumber: '0',
  isVerified: false,
  sharedUserIsVerified: false,
  pinned: false,
);
