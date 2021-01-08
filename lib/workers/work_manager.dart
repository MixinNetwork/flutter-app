// todo worker loops manager
import 'dart:async';

import 'package:flutter_app/db/database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'reciver_worker.dart';

class WorkManager {
  WorkManager(this.selfId, this.database, this.client) {
    assert(selfId != null);
    assert(database != null);
    assert(client != null);
  }
  String selfId;
  Database database;
  Client client;

  Timer _timber;
  bool _running = false;
  void start() {
    _timber ??= Timer.periodic(const Duration(milliseconds: 200), (timer) {
      while (_timber != null && !_running) {
        _running = true;
        _process();
        _running = false;
      }
    });
  }

  void stop() {
    if (_timber != null) {
      _timber = null;
    }
  }

  void _process() {
    if (_receiveWorker == null) {
      _receiveWorker.doWork();
    }
  }

  ReceiveWorker _receiveWorker;
}
