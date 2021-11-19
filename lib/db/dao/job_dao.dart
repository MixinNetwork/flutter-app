import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../../constants/constants.dart';
import '../mixin_database.dart';

part 'job_dao.g.dart';

@DriftAccessor(tables: [MessagesHistory])
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

  Stream<bool> _watchHasJobs(String action) => db
      .watchHasData(db.jobs, [],
          db.jobs.action.equals(action) & db.jobs.blazeMessage.isNotNull())
      .where((event) => event)
      .throttleTime(const Duration(milliseconds: 50), trailing: true);

  Stream<bool> watchHasAckJobs() => _watchHasJobs(acknowledgeMessageReceipts);

  SimpleSelectStatement<Jobs, Job> ackJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(acknowledgeMessageReceipts) &
        row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasSessionAckJobs() => _watchHasJobs(createMessage);

  SimpleSelectStatement<Jobs, Job> sessionAckJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(createMessage) & row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasRecallMessageJobs() => _watchHasJobs(recallMessage);

  SimpleSelectStatement<Jobs, Job> recallMessageJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(recallMessage) & row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasPinMessageJobs() => _watchHasJobs(pinMessage);

  SimpleSelectStatement<Jobs, Job> pinMessageJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(pinMessage) & row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasSendingJobs() => _watchHasJobs(sendingMessage);

  SimpleSelectStatement<Jobs, Job> sendingJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(sendingMessage) & row.blazeMessage.isNotNull())
    ..limit(100);

  Future<Job?> ackJobById(String jobId) =>
      (select(db.jobs)..where((tbl) => tbl.jobId.equals(jobId)))
          .getSingleOrNull();

  Future<void> insertAll(List<Job> jobs) => batch((batch) {
        batch.insertAllOnConflictUpdate(db.jobs, jobs);
      });

  Future<void> insertNoReplace(Job job) async {
    final exists = await ackJobById(job.jobId);
    if (exists == null) {
      await insert(job);
    }
  }
}
