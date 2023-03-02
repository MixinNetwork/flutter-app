import 'dart:async';

import '../db/database.dart';
import '../utils/logger.dart';

abstract class JobQueue<T> {
  JobQueue({required this.database}) {
    start();
  }

  final Database database;

  bool isRunning = false;

  bool get enable => true;

  String get name;

  Future<List<T>> fetchJobs();

  Future<List<T>?> run(List<T> jobs);

  Future<void> insertJob(T job);

  void start() => unawaited(_run());

  Future<void> add(T job) async {
    await insertJob(job);
    unawaited(_run());
  }

  Future<void> _run() async {
    if (isRunning) return;
    isRunning = true;

    while (true) {
      final list = await fetchJobs();
      if (list.isEmpty) break;
      try {
        await run(list);
      } catch (err) {
        e('[init] $name run error: $err');
      }
    }
    isRunning = false;
  }
}
