import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/constans.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/workers/work_manager.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

class AccountServer {
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
    workManager = WorkManager(userId, database, client);
  }

  String userId;
  String sessionId;
  String identityNumber;
  String privateKey;

  Client client;
  Database database;
  Blaze blaze;
  WorkManager workManager;

  void start() {
    blaze.connect();
    // workManager.start();
  }

  void sendMessage() {
    assert(database != null);
    assert(blaze != null);
    assert(workManager != null);
    // todo insert sending message
  }

  void stop() {
    blaze.disconnect();
    // workManager.stop();
  }

  void relase() {
    // todo relase resource
  }
}
