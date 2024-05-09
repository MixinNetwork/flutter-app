import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../constants/constants.dart';
import '../../utils/logger.dart';
import '../database_event_bus.dart';
import '../mixin_database.dart';

part 'job_dao.g.dart';

class MiniJobItem with EquatableMixin {
  const MiniJobItem({
    required this.jobId,
    required this.action,
  });

  final String jobId;
  final String action;

  @override
  List<Object?> get props => [
        jobId,
        action,
      ];
}

@DriftAccessor()
class JobDao extends DatabaseAccessor<MixinDatabase> with _$JobDaoMixin {
  JobDao(super.db);

  static const messageIdKey = 'message_id';
  static const recipientIdKey = 'recipient_id';
  static const silentKey = 'silent';
  static const expireInKey = 'expireIn';

  Future<int> insert(Job job) =>
      into(db.jobs).insertOnConflictUpdate(job).whenComplete(
            () => DataBaseEventBus.instance.addJob(
              MiniJobItem(jobId: job.jobId, action: job.action),
            ),
          );

  Future<Job> createSendingJob(
    String messageId,
    String conversationId, {
    String? recipientId,
    bool silent = false,
    int? expireIn,
  }) async {
    Future<int> getConversationExpireIn() async {
      final conversation = await db.conversationDao
          .conversationItem(conversationId)
          .getSingleOrNull();
      return conversation?.expireIn ?? 0;
    }

    d('insertSendingJob: ${expireIn ?? (await getConversationExpireIn())}');

    return Job(
      jobId: const Uuid().v4(),
      action: kSendingMessage,
      priority: 5,
      blazeMessage: jsonEncode({
        messageIdKey: messageId,
        recipientIdKey: recipientId,
        silentKey: silent,
        expireInKey: expireIn ?? (await getConversationExpireIn()),
      }),
      conversationId: conversationId,
      createdAt: DateTime.now(),
      runCount: 0,
    );
  }

  Future<void> deleteJobs(List<String> jobIds) => batch(
      (b) => b.deleteWhere(db.jobs, (Jobs row) => row.jobId.isIn(jobIds)));

  Future<void> deleteJobById(String jobId) => batch(
      (b) => b.deleteWhere(db.jobs, (Jobs row) => row.jobId.equals(jobId)));

  Future<void> deleteJobByAction(String action) => batch(
      (b) => b.deleteWhere(db.jobs, (Jobs row) => row.action.equals(action)));

  SimpleSelectStatement<Jobs, Job> ackJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kAcknowledgeMessageReceipts) &
        row.blazeMessage.isNotNull())
    ..limit(100);

  SimpleSelectStatement<Jobs, Job> sessionAckJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kCreateMessage) & row.blazeMessage.isNotNull())
    ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
    ..limit(100);

  SimpleSelectStatement<Jobs, Job> sendingJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.isIn([kSendingMessage, kPinMessage, kRecallMessage]) &
        row.blazeMessage.isNotNull())
    ..limit(100);

  SimpleSelectStatement<Jobs, Job> updateAssetJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kUpdateAsset) & row.blazeMessage.isNotNull())
    ..limit(100);

  SimpleSelectStatement<Jobs, Job> updateTokenJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kUpdateToken) & row.blazeMessage.isNotNull())
    ..limit(100);

  SimpleSelectStatement<Jobs, Job> syncInscriptionMessageJobs() =>
      select(db.jobs)
        ..where((Jobs row) =>
            row.action.equals(kSyncInscriptionMessage) &
            row.blazeMessage.isNotNull())
        ..limit(100);

  SimpleSelectStatement<Jobs, Job> updateStickerJobs() => select(db.jobs)
    ..where((Jobs row) => row.action.equals(kUpdateSticker))
    ..limit(100);

  SimpleSelectStatement<Jobs, Job> migrateFtsJobs() =>
      select(db.jobs)..where((Jobs row) => row.action.equals(kMigrateFts));

  SimpleSelectStatement<Jobs, Job> jobByAction(String action) =>
      select(db.jobs)..where((Jobs row) => row.action.equals(action));

  Future<Job?> jobById(String jobId) =>
      (select(db.jobs)..where((tbl) => tbl.jobId.equals(jobId)))
          .getSingleOrNull();

  Future<void> insertAll(List<Job> jobs) => batch((batch) {
        batch.insertAllOnConflictUpdate(db.jobs, jobs);
      }).whenComplete(() {
        for (final job in jobs) {
          DataBaseEventBus.instance.addJob(
            MiniJobItem(jobId: job.jobId, action: job.action),
          );
        }
      });

  Future<void> insertNoReplace(Job job) async {
    final exists = await jobById(job.jobId);
    if (exists == null) {
      await insert(job);
    }
  }
}
