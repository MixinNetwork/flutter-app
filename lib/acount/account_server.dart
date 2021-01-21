import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:flutter_app/utils/stream_extension.dart';

class AccountServer {
  static String sid;

  void initServer(
    String userId,
    String sessionId,
    String identityNumber,
    String privateKey,
  ) {
    assert(userId != null);
    assert(sessionId != null);
    assert(identityNumber != null);
    assert(privateKey != null);
    this.userId = userId;
    this.sessionId = sessionId;
    this.identityNumber = identityNumber;
    this.privateKey = privateKey;
    database = Database(identityNumber);
    client = Client();
    (client.dio.transformer as DefaultTransformer).jsonDecodeCallback =
        LoadBalancerUtils.jsonDecode;
    client.initMixin(userId, sessionId, privateKey, scp);
    blaze = Blaze(userId, sessionId, privateKey, database, client);
    _decryptMessage = DecryptMessage(userId, database, client);
  }

  String userId;
  String sessionId;
  String identityNumber;
  String privateKey;

  Client client;
  Database database;
  Blaze blaze;
  DecryptMessage _decryptMessage;

  void start() {
    // sendPort?.send('start account');
    // todo remove, development only
    if (sid == sessionId) {
      return;
    }
    sid = sessionId;
    blaze.connect();
    database.floodMessagesDao.findFloodMessage().listen((list) {
      if (list?.isNotEmpty == true) {
        for (final message in list) {
          _decryptMessage.process(message);
        }
      }
    });
    database.jobsDao
        .findAckJobs()
        .where((jobs) => jobs?.isNotEmpty == true)
        .asyncMapDrop(runAckJob)
        .listen((_) {});
    database.mock();
  }

  Future<void> runAckJob(List<Job> jobs) async {
    final ack = await Future.wait(jobs.map((e) async {
      final map = await LoadBalancerUtils.jsonDecode(e.blazeMessage);
      return BlazeAckMessage(messageId: map['id'], status: map['status']);
    }));

    final jobIds = jobs.map((e) => e.jobId).toList();
    await client.messageApi.acknowledgements(ack);
    await database.jobsDao.deleteJobs(jobIds);
  }

  void sendMessage() {
    assert(database != null);
    assert(blaze != null);
    // todo insert sending message
  }

  void stop() {
    blaze.disconnect();
    database.dispose();
  }

  void release() {
    // todo release resource
  }
}
