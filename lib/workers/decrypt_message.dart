import 'dart:convert';

import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/blaze_message_data.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'injector.dart';

class DecryptMessage extends Injector {
  DecryptMessage(String selfId, Database database, Client client)
      : super(selfId, database, client);

  void process(FloodMessage floodMessage) {
    final data = BlazeMessageData.fromJson(jsonDecode(floodMessage.data));
    if (data.conversationId != null) {
      syncConversion(data.conversationId);
    }
    final category = data.category;
    if (category.startsWith('SIGNAL_')) {
      // processSignalMessage(data);
      // todo decrypt
      processDecryptSuccess(data, 'Signal Message');
    } else if (category.startsWith('PLAIN_')) {
      processPlainMessage(data);
    } else if (category.startsWith('SYSTEM_')) {
      processSystemMessage(data);
    } else if (category == 'APP_BUTTON_GROUP' || category == 'APP_CARD') {
      processApp(data);
    } else if (category == 'MESSAGE_RECALL') {
      processRecallMessage(data);
    }
    _updateRemoteMessageStatus(floodMessage.messageId, MessageStatus.delivered);
    database.floodMessagesDao.deleteFloodMessage(floodMessage);
  }

  void processSignalMessage(data) {}

  void processPlainMessage(BlazeMessageData data) {
    if (data.category == MessageCategory.plainJson) {
      // todo
    } else if (data.category == MessageCategory.plainText ||
        data.category == MessageCategory.plainImage ||
        data.category == MessageCategory.plainVideo ||
        data.category == MessageCategory.plainData ||
        data.category == MessageCategory.plainAudio ||
        data.category == MessageCategory.plainContact ||
        data.category == MessageCategory.plainLive ||
        data.category == MessageCategory.plainPost ||
        data.category == MessageCategory.plainLocation) {
      if (data.representativeId?.isNotEmpty == true) {
        data.userId = data.representativeId;
      }
      processDecryptSuccess(data, data.data);
    }
  }

  void processSystemMessage(data) {}

  void processApp(data) {}

  void processRecallMessage(data) {}

  void processDecryptSuccess(BlazeMessageData data, String plainText) async {
    // todo
    // ignore: unused_local_variable
    final user = await syncUser(data.userId);

    // todo process quote message

    if (data.category.endsWith('_TEXT')) {
      String plain;
      if (data.category == MessageCategory.signalText) {
        plain = 'SignalText';
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.userId,
        category: data.category,
        content: plain,
        status: data.status,
        createdAt: data.createdAt,
      );
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_IMAGE')) {
    } else if (data.category.endsWith('_VIDEO')) {
    } else if (data.category.endsWith('_DATA')) {
    } else if (data.category.endsWith('_AUDIO')) {
    } else if (data.category.endsWith('_STICKER')) {
    } else if (data.category.endsWith('_CONTACT')) {
    } else if (data.category.endsWith('_LIVE')) {
    } else if (data.category.endsWith('_LOCATION')) {
    } else if (data.category.endsWith('_POST')) {}

    _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
  }

  void _updateRemoteMessageStatus(messageId, status) {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    final blazeMessage = BlazeMessage(messageId, status: status);
    // ignore: avoid_print
    database.jobsDao.insert(Job(
        jobId: Uuid().v4(),
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: jsonEncode(blazeMessage),
        createdAt: DateTime.now(),
        runCount: 0));
  }
}
