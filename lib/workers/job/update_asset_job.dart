import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/constants.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../job_queue.dart';

class UpdateAssetJob extends JobQueue<Job, List<Job>> {
  UpdateAssetJob({required super.database, required this.client});

  final Client client;

  @override
  String get name => 'UpdateAssetJob';

  @override
  Future<List<Job>> fetchJobs() => database.jobDao.updateAssetJobs().get();

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  @override
  Future<void> insertJob(Job job) async {
    if (job.blazeMessage == null) return;

    final jobs = database.mixinDatabase.jobs;
    final exists = await database.mixinDatabase.hasData(
      jobs,
      [],
      jobs.action.equals(kUpdateAsset) &
          jobs.blazeMessage.equals(job.blazeMessage!),
    );

    if (exists) return;

    await database.jobDao.insert(job);
  }

  @override
  Future<void> run(List<Job> jobs) async {
    final assetIds = await Future.wait<String?>(
      jobs.map((Job job) async {
        try {
          final asset = (await client.assetApi.getAssetById(
            job.blazeMessage!,
          )).data;

          final chain = (await client.assetApi.getChain(asset.chainId)).data;

          await Future.wait([
            database.assetDao.insertSdkAsset(asset),
            database.chainDao.insertSdkChain(chain),
            database.jobDao.deleteJobById(job.jobId),
          ]);
          return asset.assetId;
        } catch (e, s) {
          w('Update asset job error: $e, stack: $s');
          await Future.delayed(const Duration(seconds: 1));
        }
      }),
    );

    DataBaseEventBus.instance.updateAsset(assetIds.nonNulls);
  }
}
