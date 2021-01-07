import 'package:flutter_app/constans.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/mixin_client.dart';

class BaseWorker {
  Future<void> syncConversion(String conversationId) async {
    // print(conversationId);
    if (conversationId == null || conversationId == systemUser) {
      return;
    }
    final result =
        await Database().conversationDao.getConversationById(conversationId);
    // print(result);
    if (result.isEmpty) {
      final response = await MixinClient()
          .client
          .conversationApi
          .getConversation(conversationId);
      if (response.data != null) {
        await Database().conversationDao.insert(Conversation(
            conversationId: response.data.conversationId,
            ownerId: response.data.creatorId,
            category: response.data.category,
            name: response.data.name,
            announcement: response.data.announcement,
            createdAt: response.data.createdAt,
            status: ConversationStatus.success.index,
            muteUntil: response.data.muteUntil));
      }
    }
  }
}
