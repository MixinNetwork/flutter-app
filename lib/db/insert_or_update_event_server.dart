import 'dart:async';

import 'package:flutter_app/db/mixin_database.dart';

class InsertOrUpdateEventServer {
  final conversationInsertOrUpdateController =
      StreamController<String>.broadcast();

  Stream<ConversationItem> conversationInsertOrUpdateStream;

  void dispose() {
    conversationInsertOrUpdateController.close();
  }
}
