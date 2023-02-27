import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../constants/constants.dart';
import '../../utils/logger.dart';
import '../mixin_database.dart';

part 'job_dao.g.dart';

@DriftAccessor(tables: [MessagesHistory])
class JobDao extends DatabaseAccessor<MixinDatabase> with _$JobDaoMixin {
  JobDao(super.db);

  static const messageIdKey = 'message_id';
  static const recipientIdKey = 'recipient_id';
  static const silentKey = 'silent';
  static const expireInKey = 'expireIn';

  Future<int> insert(Job job) => into(db.jobs).insertOnConflictUpdate(job);

  Future<int> insertSendingJob(
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

    return insert(
      Job(
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
      ),
    );
  }

  Future deleteJob(Job job) => delete(db.jobs).delete(job);

  Future<void> deleteJobs(List<String> jobIds) => batch(
      (b) => {b.deleteWhere(db.jobs, (Jobs row) => row.jobId.isIn(jobIds))});

  Future<void> deleteJobById(String jobId) => batch(
      (b) => {b.deleteWhere(db.jobs, (Jobs row) => row.jobId.equals(jobId))});

  Stream<bool> _watchHasJobs(List<String> actions) => db
      .watchHasData(db.jobs, [],
          db.jobs.action.isIn(actions) & db.jobs.blazeMessage.isNotNull())
      .where((event) => event);

  Stream<bool> watchHasAckJobs() =>
      _watchHasJobs([kAcknowledgeMessageReceipts]);

  SimpleSelectStatement<Jobs, Job> ackJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kAcknowledgeMessageReceipts) &
        row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasSessionAckJobs() => _watchHasJobs([kCreateMessage]);

  SimpleSelectStatement<Jobs, Job> sessionAckJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kCreateMessage) & row.blazeMessage.isNotNull())
    ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
    ..limit(100);

  Stream<bool> watchHasSendingJobs() =>
      _watchHasJobs([kSendingMessage, kPinMessage, kRecallMessage]);

  SimpleSelectStatement<Jobs, Job> sendingJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.isIn([kSendingMessage, kPinMessage, kRecallMessage]) &
        row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasUpdateAssetJobs() => _watchHasJobs([kUpdateAsset]);

  SimpleSelectStatement<Jobs, Job> updateAssetJobs() => select(db.jobs)
    ..where((Jobs row) =>
        row.action.equals(kUpdateAsset) & row.blazeMessage.isNotNull())
    ..limit(100);

  Stream<bool> watchHasUpdateStickerJobs() => _watchHasJobs([kUpdateSticker]);

  SimpleSelectStatement<Jobs, Job> updateStickerJobs() => select(db.jobs)
    ..where((Jobs row) => row.action.equals(kUpdateSticker))
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

  Future<void> insertUpdateAssetJob(String assetId) async {
    final exists = await db.hasData(
        db.jobs,
        [],
        db.jobs.action.equals(kUpdateAsset) &
            db.jobs.blazeMessage.equals(assetId));
    if (exists) return;
    await insert(Job(
      jobId: const Uuid().v4(),
      action: kUpdateAsset,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: assetId,
    ));
  }

  Future<void> insertUpdateStickerJob(String stickerId) async {
    final exists = await db.hasData(
        db.jobs,
        [],
        db.jobs.action.equals(kUpdateSticker) &
            db.jobs.blazeMessage.equals(stickerId));
    if (exists) return;
    await insert(Job(
      jobId: const Uuid().v4(),
      action: kUpdateSticker,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: stickerId,
    ));
  }
}
