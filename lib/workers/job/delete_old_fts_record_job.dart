import '../../utils/logger.dart';
import '../job_queue.dart';

class DeleteOldFtsRecordJob extends JobQueue<bool, List<bool>> {
  DeleteOldFtsRecordJob({required super.database});

  @override
  Future<List<bool>> fetchJobs() async {
    // check if messages_fts table exists in mixinDatabase
    final exists = await database.mixinDatabase
        .customSelect(
          "select EXISTS(SELECT 1 FROM sqlite_master WHERE type='table' AND name='messages_fts') as result",
        )
        .map((row) => row.read<bool>('result'))
        .getSingle();
    if (!exists) {
      e('DeleteOldFtsRecordJob: messages_fts table not exists');
      return [];
    }

    final hasRecord = await database.mixinDatabase
        .customSelect(
          'select EXISTS(select 1 from messages_fts limit 1) as result',
        )
        .map((row) => row.read<bool>('result'))
        .getSingle();
    if (hasRecord) return [hasRecord];
    return [];
  }

  @override
  Future<void> insertJob(bool job) async {
    assert(false, 'DeleteOldFtsRecordJob should not insert job');
  }

  @override
  String get name => 'DeleteOldFtsRecordJob';

  @override
  Future<void> run(List<bool> jobs) async {
    final stopwatch = Stopwatch()..start();
    var deleted = 0;
    while (true) {
      if (deleted >= 5000) {
        i(
          'DeleteOldFtsRecordJob: $deleted records deleted ${stopwatch.elapsed}',
        );
        stopwatch.reset();
        deleted = 0;
      }

      final list = await fetchJobs();
      if (list.isEmpty) {
        i('delete old fts record job finished');
        return;
      }

      await database.mixinDatabase.customStatement(
        'DELETE FROM messages_fts WHERE rowid IN (SELECT rowid FROM messages_fts LIMIT 1000)',
      );

      deleted += 1000;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  bool isValid(List<bool> jobs) => jobs.isNotEmpty;
}
