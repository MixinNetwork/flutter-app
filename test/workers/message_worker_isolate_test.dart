@TestOn('linux || mac-os')
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_app/workers/message_worker_isolate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  setUpAll(EventBus.initialize);

  test(
    'rebuilds a future expiration timer through the worker event queue',
    () async {
      final database = MixinDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.expiredMessageDao.insert(
        messageId: 'future-expiration',
        expireIn: 1,
        expireAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3,
      );

      Timer? timer;
      var runs = 0;
      final timerScheduled = Completer<void>();
      final messageExpired = Completer<void>();
      final cleanupRunFinished = Completer<void>();

      Future<void> schedule() async {
        timer = await runExpiredMessageScheduler(
          expiredMessageDao: database.expiredMessageDao,
          previousTimer: timer,
          onTimer: DataBaseEventBus.instance.updateExpiredMessageTable,
          expireMessage: (message) async {
            await database.expiredMessageDao.deleteByMessageId(
              message.messageId,
            );
            if (!messageExpired.isCompleted) messageExpired.complete();
          },
        );
        runs += 1;
        if (runs == 1 && !timerScheduled.isCompleted) {
          timerScheduled.complete();
        }
        if (runs == 2 && !cleanupRunFinished.isCompleted) {
          cleanupRunFinished.complete();
        }
      }

      final subscription = DataBaseEventBus
          .instance
          .updateExpiredMessageTableStream
          .startWith(null)
          .asyncBufferMap((_) => schedule())
          .listen((_) {});
      addTearDown(() async {
        await subscription.cancel();
        timer?.cancel();
      });

      await timerScheduled.future.timeout(const Duration(seconds: 1));
      expect(timer, isNotNull);

      await messageExpired.future.timeout(const Duration(seconds: 5));
      await cleanupRunFinished.future.timeout(const Duration(seconds: 1));
      expect(runs, greaterThanOrEqualTo(2));
      expect(
        await database.expiredMessageDao
            .getFirstExpiredMessage()
            .getSingleOrNull(),
        isNull,
      );
    },
  );
}
