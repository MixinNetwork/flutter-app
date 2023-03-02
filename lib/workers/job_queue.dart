import 'dart:async';
import 'dart:math';

import '../db/database.dart';
import '../utils/logger.dart';

abstract class JobQueue<T> {
  JobQueue({required this.database}) {
    start();
  }

  final Database database;
  final List<T> queue = [];

  bool isRunning = false;
  bool initialized = false;

  bool get enable => true;

  String get name;

  Future<List<T>> initFetchJobs();

  Future<List<T>?> run(List<T> jobs);

  Future<bool> insertJob(T job);

  void start() => unawaited(_run());

  Future<void> add(T job) async {
    await insertJob(job);
    queue.add(job);
    d('JobQueue $name add job, queue.length: ${queue.length}\n${StackTrace.current}\n');
    unawaited(_run());
  }

  Future<void> _run() async {
    if (isRunning) return;
    isRunning = true;

    if (!initialized) {
      while (true) {
        final list = await initFetchJobs();
        if (list.isEmpty) break;
        try {
          await run(list);
        } catch (err) {
          e('[init] $name run error: $err');
        }
      }
      initialized = true;
    }

    while (true) {
      final index = min(100, queue.length);
      d('JobQueue $name index: $index, queue.length: ${queue.length}\n');

      final pendingList = queue.sublist(0, index).toList();
      queue.removeRange(0, index);

      if (pendingList.isEmpty) break;

      try {
        d('JobQueue $name run before jobs.length: ${pendingList.length}\n');
        final stopwatch = Stopwatch()..start();
        final failedJobs = await run(pendingList);
        d('JobQueue $name run after ${stopwatch.elapsed} jobs.length: ${pendingList.length} failedJobs.length: ${failedJobs?.length ?? 0} \n');

        if (failedJobs != null && failedJobs.isNotEmpty) {
          queue.addAll(failedJobs);
        }
      } catch (err, s) {
        e('$name run error: $err\n$s');
      }
    }

    isRunning = false;
  }
}
