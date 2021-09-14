import 'dart:convert';

import 'package:moor/moor.dart';
import 'package:uuid/uuid.dart';

import '../../constants/constants.dart';
import '../mixin_database.dart';

part 'job_dao.g.dart';

@UseDao(tables: [MessagesHistory])
class JobDao extends DatabaseAccessor<MixinDatabase> with _$JobDaoMixin {
  JobDao(MixinDatabase db) : super(db);

  static const messageIdKey = 'message_id';
  static const recipientIdKey = 'recipient_id';
  static const silentKey = 'silent';

  Future<int> insert(Job job) => into(db.jobs).insertOnConflictUpdate(job);

  Future<int> insertSendingJob(
    String messageId,
    String conversationId, {
    String? recipientId,
    bool silent = false,
  }) =>
      insert(
        Job(
          jobId: const Uuid().v4(),
          action: sendingMessage,
          priority: 5,
          blazeMessage: jsonEncode({
            messageIdKey: messageId,
            recipientIdKey: recipientId,
            silentKey: silent,
          }),
          conversationId: conversationId,
          createdAt: DateTime.now(),
          runCount: 0,
        ),
      );

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

  Stream<List<Job>> findPinMessageJobs() {
    final query = select(db.jobs)
      ..where((Jobs row) => row.action.equals(pinMessage))
      ..limit(100);
    return query.watch();
  }

  Stream<List<Job>> findSendingJobs() {
    final query = select(db.jobs)
      ..where((Jobs row) => row.action.equals(sendingMessage))
      ..limit(100);
    return query.watch();
  }

  Future<void> insertAll(List<Job> jobs) => batch((batch) {
        batch.insertAllOnConflictUpdate(db.jobs, jobs);
      });

  Future<void> insertNoReplace(Job job) async {
    final exists = await findAckJobById(job.jobId);
    if (exists == null) {
      await insert(job);
    }
  }
}
