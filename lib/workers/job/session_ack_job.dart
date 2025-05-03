import 'dart:convert';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';

import '../../blaze/blaze_message.dart';
import '../../blaze/vo/plain_json_message.dart';
import '../../constants/constants.dart';
import '../../crypto/uuid/uuid.dart';
import '../../db/mixin_database.dart';
import '../../utils/load_balancer_utils.dart';
import '../job_queue.dart';
import '../sender.dart';

class SessionAckJob extends JobQueue<List<Job>, List<Job>> {
  SessionAckJob({
    required super.database,
    required this.userId,
    required this.primarySessionId,
    required this.sender,
  });

  final String userId;
  final String? primarySessionId;
  final Sender sender;

  @override
  bool get enable => primarySessionId != null;

  @override
  String get name => 'SessionAckJob';

  @override
  Future<void> insertJob(List<Job> jobs) => database.jobDao.insertAll(jobs);

  @override
  Future<List<Job>> fetchJobs() => database.jobDao.sessionAckJobs().get();

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  @override
  Future<List<Job>?> run(List<Job> jobs) async {
    if (primarySessionId == null) return jobs;

    final conversationId =
        await database.participantDao.findJoinedConversationId(userId) ??
        generateConversationId(userId, kTeamMixinUserId);

    final ack = await Future.wait(
      jobs.map((e) async {
        final map = jsonDecode(e.blazeMessage!) as Map<String, dynamic>;
        return BlazeAckMessage.fromJson(map);
      }),
    );

    final stopwatch = Stopwatch()..start();

    final jobIds = jobs.map((e) => e.jobId).toList();

    final plainText = PlainJsonMessage(
      kAcknowledgeMessageReceipts,
      null,
      null,
      null,
      null,
      ack,
    );
    final encode = await base64EncodeWithIsolate(
      await utf8EncodeWithIsolate(await jsonEncodeWithIsolate(plainText)),
    );
    // TODO check if safety to use a primary session.
    // final primarySessionId = AccountKeyValue.instance.primarySessionId;
    final param = createPlainJsonParam(
      conversationId,
      userId,
      encode,
      sessionId: primarySessionId,
    );
    final bm = createParamBlazeMessage(param);

    final result = await sender.deliver(bm);
    i(
      'session ack, ${stopwatch.elapsed} ids: ${ack.map((e) => e.messageId).toList()}, BlazeMessage.id: ${bm.id}, param.messageId: ${param.messageId}',
    );
    if (result.success || result.errorCode == badData) {
      await database.jobDao.deleteJobs(jobIds);
    } else {
      return jobs;
    }
  }
}
