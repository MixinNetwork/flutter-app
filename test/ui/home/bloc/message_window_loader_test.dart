import 'dart:async';

import 'package:flutter_app/db/dao/message_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/bloc/message_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test(
    'centered loads start before, after, and center queries together',
    () async {
      final calls = <String>[];
      final beforeCompleter = Completer<List<MessageItem>>();
      final afterCompleter = Completer<List<MessageItem>>();
      final centerCompleter = Completer<MessageItem?>();

      final loader = MessageWindowLoader(
        recentMessages: (_, _) => throw StateError('unexpected recent query'),
        messageOrderInfo: (_) async => MessageOrderInfo(rowId: 2, createdAt: 2),
        beforeMessages: (_, _, _) {
          calls.add('before');
          return beforeCompleter.future;
        },
        afterMessages: (_, _, _) {
          calls.add('after');
          return afterCompleter.future;
        },
        messageById: (_) {
          calls.add('center');
          return centerCompleter.future;
        },
      );

      final future = loader.load(
        'conversation',
        6,
        centerMessageId: 'center',
      );
      await Future<void>.delayed(Duration.zero);

      expect(calls, unorderedEquals(['before', 'after', 'center']));

      centerCompleter.complete(testMessage(2));
      beforeCompleter.complete([testMessage(1)]);
      afterCompleter.complete([testMessage(3)]);

      final state = await future;

      expect(state.top.map((e) => e.messageId), ['1']);
      expect(state.center?.messageId, '2');
      expect(state.bottom.map((e) => e.messageId), ['3']);
    },
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
