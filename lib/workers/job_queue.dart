import 'dart:async';

import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../utils/logger.dart';

abstract class JobQueue<T> {
  JobQueue({required this.database}) {
    start();
  }

  @protected
  final Database database;

  @protected
  bool isRunning = false;

  @protected
  bool get enable => true;

  @protected
  String get name;

  @protected
  Future<List<T>> fetchJobs();

  @protected
  Future<void> run(List<T> jobs);

  @protected
  Future<void> insertJob(T job);

  void start() => unawaited(_run());

  Future<void> add(T job) async {
    await insertJob(job);
    unawaited(_run());
  }

  Future<void> _run() async {
    if (!enable) return;
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
