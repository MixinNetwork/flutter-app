import '../db/dao/job_dao.dart';
import '../db/mixin_database.dart';

extension JobDaoExtension on JobDao {
  Future<void> insertNoReplace(Job job) async {
    final exists = await findAckJobById(job.jobId);
    if (exists == null) {
      await insert(job);
    }
  }
}
