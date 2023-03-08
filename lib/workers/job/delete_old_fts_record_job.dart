import '../../constants/constants.dart';
import '../../db/mixin_database.dart';
import '../../utils/logger.dart';
import '../job_queue.dart';

class DeleteOldFtsRecordJob extends JobQueue<Job> {
  DeleteOldFtsRecordJob({required super.database});

  @override
  Future<List<Job>> fetchJobs() =>
      database.jobDao.deleteOldFtsRecordJobs().get();

  @override
  Future<void> insertJob(Job job) async {
    assert(false, 'DeleteOldFtsRecordJob should not insert job');
  }

  @override
  String get name => 'DeleteOldFtsRecordJob';

  @override
  Future<void> run(List<Job> jobs) async {
    // check if messages_fts table exists in mixinDatabase
    final exists = await database.mixinDatabase
        .customSelect(
            "select EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='messages_fts') as result")
        .map((row) => row.read<bool>('result'))
        .getSingle();
    if (!exists) {
      e('DeleteOldFtsRecordJob: messages_fts table not exists');
      return;
    }
    final stopwatch = Stopwatch()..start();
    while (true) {
      final hasRecord = await database.mixinDatabase
          .customSelect(
              'select EXISTS(select 1 from messages_fts limit 1) as result')
          .map((row) => row.read<bool>('result'))
          .getSingle();
      if (!hasRecord) {
        i('delete old fts record job finished');
        await database.jobDao.deleteJobByAction(kDeleteOldFtsRecord);
        return;
      }

      await database.mixinDatabase.customStatement(
        'DELETE FROM messages_fts WHERE rowid = (SELECT rowid FROM messages_fts LIMIT 1000)',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      stopwatch.reset();
    }
  }
}
