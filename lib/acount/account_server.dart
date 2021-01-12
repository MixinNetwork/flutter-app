import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/constans.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class AccountServer {
  static SendPort sendPort;
  static String sid;
  static void initIsolate() async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_isolate, receivePort.sendPort);
    sendPort = receivePort.sendPort;
  }

  static void _isolate(SendPort sendPort) async {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    // todo
  }

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
  }

  String userId;
  String sessionId;
  String identityNumber;
  String privateKey;

  Client client;
  Database database;
  Blaze blaze;

  void start() {
    // sendPort?.send('start account');
    // todo remove, development only
    if(sid == sessionId){
      return;
    }
    sid = sessionId;
    blaze.connect();
    database.floodMessagesDao.findFloodMessage().listen((list) {
      if (list?.isNotEmpty == true) {
        for (final message in list) {
          DecryptMessage(userId, database, client).process(message);
        }
      }
    });
    database.jobsDao.findAckJobs().listen((jobs) {
      if (jobs?.isNotEmpty == true) {
        final ack = jobs.map((e) {
          final map = jsonDecode(e.blazeMessage);
          return BlazeAckMessage(
              messageId: map['message_id'], status: map['status']);
        }).toList();
        client.messageApi.acknowledgements(ack).then((value) => {
          database.jobsDao.deleteJobs(jobs)
        });
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
    // todo dispose stream, https://github.com/simolus3/moor/issues/290

  }

  void relase() {
    // todo relase resource
  }
}
