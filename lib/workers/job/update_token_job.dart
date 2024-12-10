import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../constants/constants.dart';
import '../../db/database_event_bus.dart';
import '../../db/mixin_database.dart';
import '../job_queue.dart';

class UpdateTokenJob extends JobQueue<Job, List<Job>> {
  UpdateTokenJob({
    required super.database,
    required this.client,
  });

  final Client client;

  @override
  String get name => 'UpdateTokenJob';

  @override
  Future<List<Job>> fetchJobs() => database.jobDao.updateTokenJobs().get();

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  @override
  Future<void> insertJob(Job job) async {
    if (job.blazeMessage == null) return;

    final jobs = database.mixinDatabase.jobs;
    final exists = await database.mixinDatabase.hasData(
      jobs,
      [],
      jobs.action.equals(kUpdateToken) &
          jobs.blazeMessage.equals(job.blazeMessage!),
    );

    if (exists) return;

    await database.jobDao.insert(job);
  }

  final _retryDelay = <String, int>{};

  @override
  Future<void> run(List<Job> jobs) async {
    final tokenIds = await Future.wait<String?>(jobs.map((Job job) async {
      try {
        final token =
            (await client.tokenApi.getAssetById(job.blazeMessage!)).data;

        final chain = (await client.assetApi.getChain(token.chainId)).data;

        await Future.wait([
          database.tokenDao.insertSdkToken(token),
          database.chainDao.insertSdkChain(chain),
          database.jobDao.deleteJobById(job.jobId),
        ]);
        return token.assetId;
      } catch (e, s) {
        w('Update token job error: $e, stack: $s');
        final retryDelay = _retryDelay[job.jobId] ?? 1;
        _retryDelay[job.jobId] = math.min(retryDelay * 2, 120);
        await Future.delayed(Duration(seconds: retryDelay));
      }
    }));
    DataBaseEventBus.instance.updateToken(tokenIds.nonNulls);
  }
}
