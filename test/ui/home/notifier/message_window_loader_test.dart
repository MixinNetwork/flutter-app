import 'dart:async';

import 'package:flutter_app/db/dao/message_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/home/notifier/message_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

void main() {
  test(
    'centered load hydrates around id window in one item query',
    () async {
      final calls = <String>[];
      final beforeIdsCompleter = Completer<List<String>>();
      final afterIdsCompleter = Completer<List<String>>();
      final hydrateCompleter = Completer<List<MessageItem>>();

      final loader = MessageWindowLoader(
        recentMessages: (_, _) => throw StateError('unexpected recent query'),
        messageOrderInfo: (_) async => MessageOrderInfo(rowId: 2, createdAt: 2),
        beforeMessageIds: (_, _, _) {
          calls.add('beforeIds');
          return beforeIdsCompleter.future;
        },
        afterMessageIds: (_, _, _) {
          calls.add('afterIds');
          return afterIdsCompleter.future;
        },
        messagesByIds: (ids) {
          calls.add('hydrate:${ids.join(',')}');
          return hydrateCompleter.future;
        },
      );

      final future = loader.load(
        'conversation',
        6,
        centerMessageId: 'center',
      );
      await Future<void>.delayed(Duration.zero);

      expect(calls, unorderedEquals(['beforeIds', 'afterIds']));

      beforeIdsCompleter.complete(['1']);
      afterIdsCompleter.complete(['3']);
      await Future<void>.delayed(Duration.zero);

      expect(calls, contains('hydrate:1,center,3'));

      hydrateCompleter.complete([
        testMessage(3),
        testMessage(1),
        testMessage(2, messageId: 'center'),
      ]);

      final state = await future;

      expect(state.top.map((e) => e.messageId), ['1']);
      expect(state.center?.messageId, 'center');
      expect(state.bottom.map((e) => e.messageId), ['3']);
    },
  );
}

MessageItem testMessage(int index, {String? messageId}) => MessageItem(
  messageId: messageId ?? '$index',
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
