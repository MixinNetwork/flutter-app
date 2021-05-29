import 'package:moor/moor.dart';
import 'package:uuid/uuid.dart';

import '../../constants/constants.dart';
import '../mixin_database.dart';

part 'jobs_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class JobsDao extends DatabaseAccessor<MixinDatabase> with _$JobsDaoMixin {
  JobsDao(MixinDatabase db) : super(db);

  Future<int> insert(Job job) => into(db.jobs).insertOnConflictUpdate(job);

  Future<int> insertSendingJob(String messageId, String conversationId) =>
      insert(Job(
          jobId: const Uuid().v4(),
          action: sendingMessage,
          priority: 5,
          blazeMessage: messageId,
          conversationId: conversationId,
          createdAt: DateTime.now(),
          runCount: 0));

  Future deleteJob(Job job) => delete(db.jobs).delete(job);

  Future<void> deleteJobs(List<String> jobIds) => batch(
      (b) => {b.deleteWhere(db.jobs, (Jobs row) => row.jobId.isIn(jobIds))});

  Future<void> deleteJobById(String jobId) => batch(
      (b) => {b.deleteWhere(db.jobs, (Jobs row) => row.jobId.equals(jobId))});

  Stream<List<Job>> findAckJobs() {
    final query = select(db.jobs)
      ..where((Jobs row) => row.action.equals(acknowledgeMessageReceipts))
      ..limit(100);
    return query.watch();
  }

  Stream<List<Job>> findSessionAckJobs() {
    final query = select(db.jobs)
      ..where((Jobs row) => row.action.equals(createMessage))
      ..limit(100);
    return query.watch();
  }

  Future<Job?> findAckJobById(String jobId) =>
      (select(db.jobs)..where((tbl) => tbl.jobId.equals(jobId)))
          .getSingleOrNull();

  Stream<List<Job>> findRecallMessageJobs() {
    final query = select(db.jobs)
      ..where((Jobs row) => row.action.equals(recallMessage))
      ..limit(100);
    return query.watch();
  }

  Stream<List<Job>> findSendingJobs() {
    final query = select(db.jobs)
      ..where((Jobs row) => row.action.equals(sendingMessage))
      ..limit(100);
    return query.watch();
  }

  Future<List<Job>> findCreateMessageJobs() => customSelect(
              'SELECT * FROM jobs WHERE `action` = \'CREATE_MESSAGE\' ORDER BY created_at ASC LIMIT 100',
              readsFrom: {
            db.jobs
          })
          .map((QueryRow row) => Job(
              jobId: row.read<String>('jobId'),
              action: row.read<String>('action'),
              orderId: row.read<int>('orderId'),
              priority: row.read<int>('priority'),
              userId: row.read<String>('userId'),
              blazeMessage: row.read<String>('jobId'),
              conversationId: row.read<String>('jobId'),
              resendMessageId: row.read<String>('resendMessageId'),
              runCount: row.read<int>('runCount'),
              createdAt: row.read<DateTime>('createdAt')))
          .get();

  Future<void> insertAll(List<Job> jobs) => batch((batch) {
        batch.insertAllOnConflictUpdate(db.jobs, jobs);
      });
}
