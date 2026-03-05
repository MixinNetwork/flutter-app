import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/constants.dart';
import '../../db/dao/message_dao.dart';
import '../../db/dao/transcript_message_dao.dart';
import '../../db/fts_database.dart';
import '../../db/mixin_database.dart';
import '../../runtime/db_write/method.dart';
import '../../runtime/db_write/payload.dart';
import '../../utils/extension/extension.dart';
import '../job_queue.dart';

/// The `MigrateFtsJob` class is responsible for migrating the old `messages_fts`
/// table from the `mixinDatabase` to a new `fts.db` file.
///
/// The fist job is created by [MixinDatabase.migration].
///
class MigrateFtsJob extends JobQueue<Job, List<Job>> {
  MigrateFtsJob({
    required super.database,
    required super.requestDbWrite,
  })
    : messageDao = database.messageDao,
      ftsDatabase = database.ftsDatabase,
      transcriptMessageDao = database.transcriptMessageDao;

  final MessageDao messageDao;
  final FtsDatabase ftsDatabase;
  final TranscriptMessageDao transcriptMessageDao;

  @override
  Future<List<Job>> fetchJobs() async {
    final jobs = await database.jobDao.migrateFtsJobs().get();
    if (jobs.isEmpty || jobs.length == 1) {
      return jobs;
    }
    if (jobs.length != 1) {
      e(
        'MigrateFtsJob: ${jobs.length} jobs found, only first job will be executed',
      );
    }
    final first = jobs.first;

    final invalidJobs = jobs.skip(1).map((e) => e.jobId).toList();
    await requestDbWrite(
      DbWriteMethod.deleteJobs,
      payload: DbWriteDeleteJobsPayload(jobIds: invalidJobs),
    );

    return [first];
  }

  @override
  Future<void> insertJob(Job job) async {
    assert(false, 'MigrateFtsJob should not insert job');
  }

  @override
  String get name => 'MigrateFtsJob';

  @override
  Future<void> run(List<Job> jobs) async {
    final Job job;

    // ensure there is only one job
    if (jobs.length > 1) {
      e(
        'MigrateFtsJob: ${jobs.length} jobs found, only latest job will be executed',
      );
      job = jobs.reduce(
        (value, element) =>
            value.createdAt.isAfter(element.createdAt) ? value : element,
      );
      // delete invalid jobs
      final invalidJobs = jobs
          .where((e) => e.jobId != job.jobId)
          .map((e) => e.jobId)
          .toList();
      await requestDbWrite(
        DbWriteMethod.deleteJobs,
        payload: DbWriteDeleteJobsPayload(jobIds: invalidJobs),
      );
    } else if (jobs.length == 1) {
      job = jobs.first;
    } else {
      e('MigrateFtsJob: running no job found');
      return;
    }

    i('$name startMigrate anchor: ${job.blazeMessage}');

    final stopwatch = Stopwatch()..start();
    var lastMessageRowId = job.blazeMessage == null
        ? null
        : int.tryParse(job.blazeMessage!);
    while (true) {
      final messages = await messageDao.getMessages(lastMessageRowId, 1000);
      if (messages.isEmpty) {
        d('migrateFtsDatabase done');
        await requestDbWrite(DbWriteMethod.deleteJobByAction, payload: kMigrateFts);
        break;
      }
      try {
        lastMessageRowId = messages.last.$1;

        // migration skip the messages already in ftsDatabase.
        final messagesToMigrate = (await Future.wait(
          messages.map((e) async {
            final exist = await ftsDatabase
                .checkMessageMetaExists(e.$2.messageId)
                .getSingle();
            return exist ? null : e.$2;
          }),
        )).nonNulls;

        final transcriptMessageFtsContent = <String, String>{};
        for (final message in messagesToMigrate) {
          if (!message.category.isTranscript) {
            continue;
          }
          final transcripts = await transcriptMessageDao
              .transcriptMessageByTranscriptId(message.messageId)
              .get();
          if (transcripts.isEmpty) {
            e('transcriptMessageByMessageId empty ${message.messageId}');
            continue;
          }
          final content = await transcriptMessageDao
              .generateTranscriptMessageFts5Content(transcripts);
          transcriptMessageFtsContent[message.messageId] = content;
        }

        await requestDbWrite(
          DbWriteMethod.migrateFtsInsertBatch,
          payload: DbWriteMigrateFtsInsertBatchPayload(
            messages: messagesToMigrate.toList(),
            transcriptContentMap: transcriptMessageFtsContent,
          ),
        );

        await requestDbWrite(
          DbWriteMethod.replaceMigrateFtsJob,
          payload: DbWriteReplaceMigrateFtsJobPayload(
            messageRowId: lastMessageRowId,
          ),
        );

        i(
          'migrateFtsDatabase(${messages.length}) elapsed: ${stopwatch.elapsed} lastMessageRowId: $lastMessageRowId',
        );
        stopwatch.reset();
      } catch (error, stacktrace) {
        e('migrateFtsDatabase error $error $stacktrace');
        // delay 1s to avoid too much CPU usage.
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;
}
