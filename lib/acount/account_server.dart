import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

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
    database.jobsDao.findAckJobs().listen((jobs) {
      if (jobs?.isNotEmpty == true) {
        final ack = jobs.map((e) {
          final map = jsonDecode(e.blazeMessage);
          return BlazeAckMessage(
              messageId: map['id'], status: map['status']);
        }).toList();
        final jobIds = jobs.map((e) => e.jobId).toList();
        client.messageApi.acknowledgements(ack).then(
            (value) => {database.jobsDao.deleteJobs(jobIds)},
            onError: (e) => debugPrint(e));
      }
    });
  }

  void sendMessage() {
    assert(database != null);
    assert(blaze != null);
    // todo insert sending message
  }

  void stop() {
    blaze.disconnect();
    database.insertOrUpdateEventServer.dispose();
    // todo dispose stream, https://github.com/simolus3/moor/issues/290
  }

  void release() {
    // todo release resource
  }
}
