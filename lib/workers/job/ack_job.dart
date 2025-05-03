import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../db/mixin_database.dart';
import '../job_queue.dart';

class AckJob extends JobQueue<List<Job>, List<Job>> {
  AckJob({required super.database, required this.client});

  final Client client;

  @override
  String get name => 'AckJob';

  @override
  Future<void> insertJob(List<Job> jobs) => database.jobDao.insertAll(jobs);

  @override
  Future<List<Job>> fetchJobs() => database.jobDao.ackJobs().get();

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  @override
  Future<void> run(List<Job> jobs) async {
    final ack = await Future.wait(
      jobs.map((e) async {
        final map = jsonDecode(e.blazeMessage!) as Map<String, dynamic>;
        return BlazeAckMessage.fromJson(map);
      }),
    );

    final jobIds = jobs.map((e) => e.jobId).toList();

    try {
      final rsp = await client.dio.post('/acknowledgements', data: ack);
      i(
        'ack ids: ${ack.map((e) => e.messageId).toList()}, request id: ${rsp.headers['x-request-id']}',
      );
      await database.jobDao.deleteJobs(jobIds);
    } catch (e, s) {
      w('Send ack error: $e, stack: $s');
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
