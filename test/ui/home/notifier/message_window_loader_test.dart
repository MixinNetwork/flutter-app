import 'dart:async';

import 'package:drift/native.dart';
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
        beforeMessages: (_, _, _) => throw StateError('unexpected before'),
        afterMessages: (_, _, _) => throw StateError('unexpected after'),
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

  test('loadBefore and loadAfter keep MessageState ordering', () async {
    final loader = MessageWindowLoader(
      recentMessages: (_, _) => throw StateError('unexpected recent query'),
      messageOrderInfo: (messageId) async => MessageOrderInfo(
        rowId: int.parse(messageId),
        createdAt: int.parse(messageId),
      ),
      beforeMessages: (_, _, _) async => [
        testMessage(2, messageId: '2'),
        testMessage(1, messageId: '1'),
      ],
      afterMessages: (_, _, _) async => [
        testMessage(4, messageId: '4'),
        testMessage(5, messageId: '5'),
      ],
      beforeMessageIds: (_, _, _) => throw StateError('unexpected before ids'),
      afterMessageIds: (_, _, _) => throw StateError('unexpected after ids'),
      messagesByIds: (_) => throw StateError('unexpected hydrate'),
    );

    final state = MessageState(
      center: testMessage(3, messageId: '3'),
    );

    final before = await loader.loadBefore(state, 'conversation', 3);
    expect(before.top.map((e) => e.messageId), ['1', '2']);
    expect(before.center?.messageId, '3');
    expect(before.isOldest, isTrue);

    final after = await loader.loadAfter(before, 'conversation', 3);
    expect(after.bottom.map((e) => e.messageId), ['4', '5']);
    expect(after.isLatest, isTrue);
  });

  test('directionFromSource compares message order', () async {
    final loader = MessageWindowLoader(
      recentMessages: (_, _) => throw StateError('unexpected recent query'),
      messageOrderInfo: (messageId) async => switch (messageId) {
        'older' => MessageOrderInfo(rowId: 1, createdAt: 1),
        'newer' => MessageOrderInfo(rowId: 2, createdAt: 1),
        _ => null,
      },
      beforeMessages: (_, _, _) => throw StateError('unexpected before'),
      afterMessages: (_, _, _) => throw StateError('unexpected after'),
      beforeMessageIds: (_, _, _) => throw StateError('unexpected before'),
      afterMessageIds: (_, _, _) => throw StateError('unexpected after'),
      messagesByIds: (_) => throw StateError('unexpected hydrate'),
    );

    expect(
      await loader.directionFromSource(
        sourceMessageId: 'newer',
        targetMessageId: 'older',
      ),
      MessageWindowDirection.older,
    );
    expect(
      await loader.directionFromSource(
        sourceMessageId: 'older',
        targetMessageId: 'newer',
      ),
      MessageWindowDirection.newer,
    );
  });

  test('message id range queries keep same-timestamp rowid ordering', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final createdAt = DateTime(2026);
    Future<void> insert(String id, DateTime time) => database
        .into(database.messages)
        .insert(
          Message(
            messageId: id,
            conversationId: 'conversation',
            userId: 'user',
            category: 'PLAIN_TEXT',
            status: MessageStatus.read,
            createdAt: time,
          ),
        );

    await insert('older', createdAt.subtract(const Duration(milliseconds: 1)));
    await insert('same-before', createdAt);
    await insert('anchor', createdAt);
    await insert('same-after', createdAt);
    await insert('newer', createdAt.add(const Duration(milliseconds: 1)));

    final anchor = await database.messageDao.messageOrderInfo('anchor');
    expect(anchor, isNotNull);

    expect(
      await database.messageDao.beforeMessageIdsByConversationId(
        anchor!,
        'conversation',
        2,
      ),
      ['same-before', 'older'],
    );
    expect(
      await database.messageDao.afterMessageIdsByConversationId(
        anchor,
        'conversation',
        2,
      ),
      ['same-after', 'newer'],
    );
  });
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
