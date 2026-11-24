@TestOn('linux || mac-os')
library;

import 'dart:async';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/database_event_bus.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/event_bus.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_app/utils/mixin_api_client.dart';
import 'package:flutter_app/workers/isolate_event.dart';
import 'package:flutter_app/workers/job_queue.dart';
import 'package:flutter_app/workers/message_worker_isolate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
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

  test('JobQueue.add persists jobs without running when stopped', () async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    addTearDown(database.dispose);

    final queue = _RecordingJobQueue(database: database)..stop();
    await queue.add('job-1');

    expect(queue.inserted, ['job-1']);
    expect(queue.runs, 0);
  });

  test(
    'WorkerApiError.fromDioException drops CancelToken and keeps auth/timing metadata',
    () async {
      final port = ReceivePort();
      addTearDown(port.close);

      final cancelToken = CancelToken();
      final requestTime = DateTime.utc(2026, 11, 24, 10);
      final options = RequestOptions(
        path: '/me',
        cancelToken: cancelToken,
        headers: {'Authorization': 'Bearer test-token'},
        extra: {kRequestTimeStampKey: requestTime},
      );

      final apiError = MixinApiError(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          headers: Headers.fromMap({
            'x-server-time': ['1763978400000000000'],
          }),
        ),
        error: MixinError(401, 401, 'Unauthorized'),
      );

      expect(() => port.sendPort.send(apiError), throwsArgumentError);

      final dto = WorkerApiError.fromDioException(apiError);
      expect(dto, isNotNull);
      expect(() => port.sendPort.send(dto), returnsNormally);
      expect(dto!.code, 401);
      expect(dto.authorizationHeader, 'Bearer test-token');
      expect(dto.requestTime, requestTime);
      expect(dto.serverTime, 1763978400000000000);

      final cancelled = DioException.requestCancelled(
        requestOptions: options,
        reason: 'timeout',
      );
      expect(WorkerApiError.fromDioException(cancelled), isNull);
    },
  );
}

class _RecordingJobQueue extends JobQueue<String, List<String>> {
  _RecordingJobQueue({required super.database});

  final inserted = <String>[];
  int runs = 0;

  @override
  String get name => 'RecordingJobQueue';

  @override
  Future<void> insertJob(String job) async => inserted.add(job);

  @override
  Future<List<String>> fetchJobs() async => List.of(inserted);

  @override
  bool isValid(List<String> job) => job.isNotEmpty;

  @override
  Future<void> run(List<String> job) async {
    runs++;
    inserted.clear();
  }
}
