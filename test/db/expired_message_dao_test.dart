@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_test/flutter_test.dart';

const _indexName = 'index_expired_messages_expire_at';

void main() {
  setUpAll(EventBus.initialize);

  test('creates a partial expire_at index for new databases', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(
      await _indexSql(database),
      allOf(
        contains('ON expired_messages (expire_at)'),
        contains('WHERE expire_at IS NOT NULL'),
      ),
    );
  });

  test('adds the partial expire_at index when migrating from v28', () async {
    final database = MixinDatabase(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase
            ..execute('''
              CREATE TABLE expired_messages (
                message_id TEXT NOT NULL,
                expire_in INTEGER NOT NULL,
                expire_at INTEGER,
                PRIMARY KEY(message_id)
              )
            ''')
            ..userVersion = 28;
        },
      ),
    );
    addTearDown(database.close);

    expect(
      await _indexSql(database),
      allOf(
        contains('ON expired_messages (expire_at)'),
        contains('WHERE expire_at IS NOT NULL'),
      ),
    );
  });

  test('loads expired messages in bounded batches', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.batch((batch) {
      batch.insertAll(database.expiredMessages, [
        for (var index = 0; index < 101; index++)
          ExpiredMessage(
            messageId: 'expired-$index',
            expireIn: 0,
            expireAt: index,
          ),
        const ExpiredMessage(
          messageId: 'not-started',
          expireIn: 0,
        ),
        ExpiredMessage(
          messageId: 'future',
          expireIn: 0,
          expireAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
        ),
      ]);
    });

    final firstBatch = await database.expiredMessageDao
        .getCurrentExpiredMessages();
    expect(firstBatch, hasLength(100));
    expect(firstBatch.first.messageId, 'expired-0');
    expect(firstBatch.last.messageId, 'expired-99');

    await database.expiredMessageDao.deleteByMessageIds(
      firstBatch.map((message) => message.messageId).toList(),
    );

    final secondBatch = await database.expiredMessageDao
        .getCurrentExpiredMessages();
    expect(secondBatch.map((message) => message.messageId), ['expired-100']);
  });

  test('notifies the scheduler when an expiration time is set', () async {
    final database = MixinDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.expiredMessageDao.insert(
      messageId: 'pending-expiration',
      expireIn: 60,
    );

    final notified = Completer<void>();
    final subscription = DataBaseEventBus
        .instance
        .updateExpiredMessageTableStream
        .listen((_) {
          if (!notified.isCompleted) notified.complete();
        });
    addTearDown(subscription.cancel);

    final updated = await database.expiredMessageDao.updateMessageExpireAt(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60,
      'pending-expiration',
    );

    expect(updated, 1);
    await notified.future.timeout(const Duration(seconds: 1));
  });
}

Future<String> _indexSql(MixinDatabase database) async {
  final row = await database
      .customSelect(
        'SELECT sql FROM sqlite_master WHERE type = ? AND name = ?',
        variables: [
          const Variable('index'),
          const Variable(_indexName),
        ],
      )
      .getSingle();
  return row.read<String>('sql');
}
