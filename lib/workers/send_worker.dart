import 'package:flutter_app/db/database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import 'base_worker.dart';

class SendWorker extends BaseWorker {
  SendWorker(String selfId, Database database, Client client)
      : super(selfId, database, client);
  void doWork() {}
}
