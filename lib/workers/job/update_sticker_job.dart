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
  Future<List<Job>?> run(List<Job> jobs) async {
    final list = await Future.wait(
      jobs.map((Job job) async {
        try {
          final stickerId = job.blazeMessage;
          if (stickerId != null) {
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
              return null;
            }
          }
          w('Update sticker job error: $e, stack: $s');
          await Future.delayed(const Duration(seconds: 1));
          return job;
        }
      }),
    );

    return list.where((element) => element != null).cast<Job>().toList();
  }
}
