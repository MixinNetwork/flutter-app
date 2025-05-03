import 'package:mixin_logger/mixin_logger.dart';

import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../job_queue.dart';

abstract class BaseMigrationJob extends JobQueue<Job, List<Job>> {
  BaseMigrationJob({required super.database, required this.action}) {
    DataBaseEventBus.instance.addJobStream
        .where((event) => event.action == action)
        .listen((event) => start());
  }

  final String action;

  @override
  Future<List<Job>> fetchJobs() async {
    final jobs = await database.jobDao.jobByAction(action).get();
    if (jobs.isEmpty || jobs.length == 1) {
      return jobs;
    }
    if (jobs.length != 1) {
      e(
        'BaseMigrationJob: $action ${jobs.length} jobs found, only first job will be executed',
      );
    }
    final first = jobs.first;

    final invalidJobs = jobs.skip(1).map((e) => e.jobId).toList();
    await database.jobDao.deleteJobs(invalidJobs);

    return [first];
  }

  @override
  Future<void> insertJob(Job job) async {
    assert(false, 'BaseMigrationJob $action should not insert job');
  }

  @override
  String get name => 'MigrationJob($action)';

  @override
  Future<void> run(List<Job> jobs) async {
    assert(
      jobs.length == 1,
      'BaseMigrationJob $action should only have one job, but got ${jobs.length}',
    );
    if (jobs.isEmpty) {
      return;
    }
    final job = jobs.first;
    assert(
      job.action == action,
      'BaseMigrationJob mismatch, expect $action, but got ${job.action}',
    );
    try {
      i('BaseMigrationJob $action start');
      await migration(job);
      i('BaseMigrationJob $action success');
      await onMigrationSuccess(job);
    } catch (error, stacktrace) {
      e('BaseMigrationJob $action error: $error, stacktrace: $stacktrace');
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> migration(Job job);

  Future<void> onMigrationSuccess(Job job) async {
    await database.jobDao.deleteJobById(job.jobId);
  }

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;
}
