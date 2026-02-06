import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/constants.dart';
import '../../db/dao/sticker_dao.dart';
import '../../db/mixin_database.dart';
import '../job_queue.dart';

class UpdateStickerJob extends JobQueue<Job, List<Job>> {
  UpdateStickerJob({required super.database, required this.client});

  final Client client;

  @override
  String get name => 'UpdateStickerJob';

  @override
  Future<List<Job>> fetchJobs() => database.jobDao.updateStickerJobs().get();

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  @override
  Future<void> insertJob(Job job) async {
    if (job.blazeMessage == null) return;

    final jobs = database.mixinDatabase.jobs;
    final exists = await database.mixinDatabase.hasData(
      jobs,
      [],
      jobs.action.equals(kUpdateSticker) &
          jobs.blazeMessage.equals(job.blazeMessage!),
    );

    if (exists) return;

    await database.jobDao.insert(job);
  }

  @override
  Future<void> run(List<Job> jobs) async {
    if (jobs.isEmpty) return;

    final now = DateTime.now();
    final first = jobs.first;
    final wait = first.createdAt.difference(now);
    if (wait.inMilliseconds > 0) {
      await Future.delayed(
        wait > const Duration(seconds: 10) ? const Duration(seconds: 10) : wait,
      );
      return;
    }

    for (final job in jobs) {
      final dueIn = job.createdAt.difference(DateTime.now());
      if (dueIn.inMilliseconds > 0) {
        break;
      }

      try {
        final stickerId = job.blazeMessage;
        if (stickerId != null && stickerId.isNotEmpty) {
          final sticker = (await client.accountApi.getStickerById(
            stickerId,
          )).data;
          await database.stickerDao.insert(sticker.asStickersCompanion);
        }
        await database.jobDao.deleteJobById(job.jobId);
      } catch (e, s) {
        if (e is MixinApiError) {
          var code = e.response?.statusCode;
          final error = e.error;
          if (code != 404 && error != null && error is MixinError) {
            code = error.code;
          }
          if (code == 404) {
            i('Sticker not found: ${job.blazeMessage}');
            await database.jobDao.deleteJobById(job.jobId);
            continue;
          }
        }

        w('Update sticker job error: $e, stack: $s');

        final nextRunAt = DateTime.now().add(_backoffDuration(job.runCount));
        await (database.mixinDatabase.update(
          database.mixinDatabase.jobs,
        )..where((tbl) => tbl.jobId.equals(job.jobId))).write(
          JobsCompanion(
            createdAt: Value(nextRunAt),
            runCount: Value(job.runCount + 1),
          ),
        );
      }
    }
  }
}

Duration _backoffDuration(int runCount) {
  if (runCount <= 0) return const Duration(minutes: 1);
  if (runCount == 1) return const Duration(minutes: 5);
  if (runCount == 2) return const Duration(minutes: 15);
  if (runCount == 3) return const Duration(hours: 1);
  return const Duration(hours: 6);
}
