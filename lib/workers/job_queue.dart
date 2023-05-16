import 'dart:async';

import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../utils/logger.dart';

abstract class JobQueue<AddType, RunType> {
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
  Future<RunType> fetchJobs();

  @protected
  Future<void> run(RunType job);

  @protected
  Future<void> insertJob(AddType job);

  @protected
  bool isValid(RunType job);

  void start() => unawaited(_run());

  Future<void> add(AddType job) async {
    await insertJob(job);
    unawaited(_run());
  }

  Future<void> _run() async {
    if (!enable) return;
    if (isRunning) return;
    isRunning = true;

    while (true) {
      final list = await fetchJobs();
      if (!isValid(list)) break;
      try {
        await run(list);
      } catch (err) {
        e('[init] $name run error: $err');
      }
    }
    isRunning = false;
  }
}
