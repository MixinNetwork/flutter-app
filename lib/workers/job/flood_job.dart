import 'package:mixin_logger/mixin_logger.dart';

import '../../db/mixin_database.dart';
import '../job_queue.dart';

class FloodJob extends JobQueue<FloodMessage> {
  FloodJob({
    required super.database,
    required this.getProcessFloodJob,
  });

  Function(FloodMessage floodMessage)? Function() getProcessFloodJob;

  @override
  Future<List<FloodMessage>> initFetchJobs() =>
      database.floodMessageDao.floodMessage().get();

  @override
  Future<bool> insertJob(FloodMessage job) async {
    await database.floodMessageDao.insert(job);
    queue.removeWhere((element) => element.messageId == job.messageId);
    return true;
  }

  @override
  bool get enable => getProcessFloodJob() != null;

  @override
  String get name => 'FloodJob';

  @override
  Future<List<FloodMessage>?> run(List<FloodMessage> jobs) async {
    final process = getProcessFloodJob();
    if (process == null) return jobs;

    final stopwatch = Stopwatch()..start();
    for (final message in jobs) {
      await process(message);
    }
    i('processMessage(${jobs.length}): ${stopwatch.elapsed}');
  }
}
