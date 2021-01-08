import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/constans.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';

import 'base_worker.dart';

class ReceiveWorker extends BaseWorker {
  ReceiveWorker(String selfId) : super(selfId);

  void doWork() async {
    final floodMessages = await Database().floodMessagesDao.findFloodMessage();
    floodMessages.forEach((floodMessage) {
      try {
        process(floodMessage);
      } catch (e) {
        debugPrint(e);
      }
    });
  }

  void process(FloodMessage floodMessage) {
    final data = jsonDecode(floodMessage.data);
    if (data['conversation_id'] != null) {
      syncConversion(data['conversation_id']);
    }
    final category = data['category'];
    if (category.startsWith('SIGNAL_')) {
      // processSignalMessage(data);
      processDecryptSuccess(data, 'SIGNAL_');
    } else if (category.startsWith('PLAIN_')) {
      // processPlainMessage(data);
      processDecryptSuccess(data, 'PLAIN_');
    } else if (category.startsWith('SYSTEM_')) {
      processSystemMessage(data);
    } else if (category == 'APP_BUTTON_GROUP' || category == 'APP_CARD') {
      processApp(data);
    } else if (category == 'MESSAGE_RECALL') {
      processRecallMessage(data);
    }
    updateRemoteMessageStatus(floodMessage.messageId, MessageStatus.delivered);
  }

  void updateRemoteMessageStatus(String messageId, String delivered) {}

  void processSignalMessage(data) {}

  void processPlainMessage(data) {}

  void processSystemMessage(data) {}

  void processApp(data) {}

  void processRecallMessage(data) {}

  void processDecryptSuccess(
      Map<String, dynamic> data, String plainText) async {
    // todo
    // ignore: unused_local_variable
    final user = await syncUser(data['user_id']);
    //
    final message = Message(
        // todo
        messageId: data['message_id'],
        conversationId: data['conversation_id'],
        userId: data['user_id'],
        category: data['category'],
        content: plainText, // todo
        status: data['status'],
        createdAt: data['created_at']);

    await Database().messagesDao.insert(message);
  }
}
