import 'package:flutter_app/db/mixin_database.dart';
import 'package:moor/moor.dart';

part 'jobs_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class JobsDao extends DatabaseAccessor<MixinDatabase> with _$JobsDaoMixin {
  JobsDao(MixinDatabase db) : super(db);

  Future<int> insert(Job job) => into(db.jobs).insertOnConflictUpdate(job);

  Future deleteJob(Job job) => delete(db.jobs).delete(job);

  void deleteJobs(List<String> jobIds) async {
    await batch(
        (b) => {b.deleteWhere(db.jobs, (Jobs row) => row.jobId.isIn(jobIds))});
  }

  Stream<List<Job>> findAckJobs() {
    // todo action error
    return customSelect('SELECT * FROM jobs ORDER BY created_at ASC LIMIT 100',
        variables: [], readsFrom: {db.jobs}).map(db.jobs.mapFromRow).watch();
  }

  Future<List<Job>> findCreateMessageJobs() {
    return customSelect(
        'SELECT * FROM jobs WHERE `action` = \'CREATE_MESSAGE\' ORDER BY created_at ASC LIMIT 100',
        readsFrom: {db.jobs}).map((QueryRow row) {
      return Job(
          jobId: row.readString('jobId'),
          action: row.readString('action'),
          orderId: row.readInt('orderId'),
          priority: row.readInt('priority'),
          userId: row.readString('userId'),
          blazeMessage: row.readString('jobId'),
          conversationId: row.readString('jobId'),
          resendMessageId: row.readString('resendMessageId'),
          runCount: row.readInt('runCount'),
          createdAt: row.readString('createdAt'));
    }).get();
  }
}
