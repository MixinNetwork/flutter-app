import '../db/mixin_database.dart';
import '../db/dao/jobs_dao.dart';

extension JobsDaoExtension on JobsDao {
  Future<void> insertNoReplace(Job job) async {
    final exists = await findAckJobById(job.jobId);
    if (exists == null) {
      insert(job);
    }
  }
}
