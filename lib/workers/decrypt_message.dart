import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_app/blaze/vo/live_message.dart';
import 'package:flutter_app/blaze/vo/attachment_message.dart';
import 'package:flutter_app/blaze/vo/blaze_message_data.dart';
import 'package:flutter_app/blaze/vo/contact_message.dart';
import 'package:flutter_app/blaze/vo/location_message.dart';
import 'package:flutter_app/blaze/vo/sticker_message.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/enum_to_string.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';
import 'injector.dart';

class DecryptMessage extends Injector {
  DecryptMessage(String selfId, Database database, Client client)
      : super(selfId, database, client);

  String _conversationId;

  void setConversationId(String conversationId) {
    _conversationId = conversationId;
  }

  void process(FloodMessage floodMessage) async {
    final data = BlazeMessageData.fromJson(
        await LoadBalancerUtils.jsonDecode(floodMessage.data));
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
    await database.floodMessagesDao.deleteFloodMessage(floodMessage);
  }

  void processSignalMessage(data) {}

  void processPlainMessage(BlazeMessageData data) {
    if (data.category == MessageCategory.plainJson) {
      // todo
      _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
    } else if (data.category == MessageCategory.plainText ||
        data.category == MessageCategory.plainImage ||
        data.category == MessageCategory.plainVideo ||
        data.category == MessageCategory.plainData ||
        data.category == MessageCategory.plainAudio ||
        data.category == MessageCategory.plainContact ||
        data.category == MessageCategory.plainSticker ||
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

    var messageStatus = MessageStatus.delivered;
    if (_conversationId != null && data.conversationId == _conversationId) {
      messageStatus = MessageStatus.read;
    }

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
        status: messageStatus,
        createdAt: data.createdAt,
      );
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_IMAGE')) {
      String plain;
      if (data.category == MessageCategory.signalImage) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final attachment =
          AttachmentMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: attachment.attachmentId,
          mediaUrl: null,
          mediaMimeType: attachment.mimeType,
          mediaSize: attachment.size,
          mediaWidth: attachment.width,
          mediaHeight: attachment.height,
          thumbImage: attachment.thumbnail,
          mediaKey: attachment.key,
          mediaDigest: attachment.digest,
          status: messageStatus,
          createdAt: data.createdAt,
          mediaStatus: MediaStatus.canceled);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_VIDEO')) {
      String plain;
      if (data.category == MessageCategory.signalVideo) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final attachment =
          AttachmentMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: attachment.attachmentId,
          name: attachment.name,
          mediaMimeType: attachment.mimeType,
          mediaDuration: attachment.duration.toString(),
          mediaSize: attachment.size,
          mediaWidth: attachment.width,
          mediaHeight: attachment.height,
          thumbImage: attachment.thumbnail,
          mediaKey: attachment.key,
          mediaDigest: attachment.digest,
          status: messageStatus,
          createdAt: data.createdAt,
          mediaStatus: MediaStatus.canceled);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_DATA')) {
      String plain;
      if (data.category == MessageCategory.signalData) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final attachment =
          AttachmentMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: attachment.attachmentId,
          name: attachment.name,
          mediaMimeType: attachment.mimeType,
          mediaSize: attachment.size,
          mediaKey: attachment.key,
          mediaDigest: attachment.digest,
          status: messageStatus,
          createdAt: data.createdAt,
          mediaStatus: MediaStatus.canceled);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_AUDIO')) {
      String plain;
      if (data.category == MessageCategory.signalAudio) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final attachment =
          AttachmentMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: attachment.attachmentId,
          name: attachment.name,
          mediaMimeType: attachment.mimeType,
          mediaSize: attachment.size,
          mediaKey: attachment.key,
          mediaDigest: attachment.digest,
          mediaWaveform: attachment.waveform,
          status: messageStatus,
          createdAt: data.createdAt,
          mediaStatus: MediaStatus.pending);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_STICKER')) {
      String plain;

      if (data.category == MessageCategory.signalSticker) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final stickerMessage =
          StickerMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      if (stickerMessage.stickerId == null) {
        // todo handle album sticker
      } else {
        // todo handle sticker
      }
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: plainText,
          name: stickerMessage.name,
          stickerId: stickerMessage.stickerId,
          albumId: stickerMessage.albumId,
          status: messageStatus,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_CONTACT')) {
      String plain;
      if (data.category == MessageCategory.signalContact) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final contactMessage =
          ContactMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      final user = await syncUser(contactMessage.userId);
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: plainText,
          name: user.fullName ?? '',
          status: messageStatus,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_LIVE')) {
      String plain;
      if (data.category == MessageCategory.signalLive) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final liveMessage =
          LiveMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          mediaWidth: liveMessage.width,
          mediaHeight: liveMessage.height,
          mediaUrl: liveMessage.url,
          thumbUrl: liveMessage.thumbUrl,
          status: messageStatus,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_LOCATION')) {
      String plain;
      if (data.category == MessageCategory.signalLocation) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
        return;
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      // ignore: unused_local_variable todo check location
      LocationMessage locationMessage;
      try {
        locationMessage =
            LocationMessage.fromJson(await LoadBalancerUtils.jsonDecode(plain));
      } catch (e) {
        debugPrint(e);
      }
      if (locationMessage == null ||
          locationMessage.latitude == 0.0 ||
          locationMessage.longitude == 0.0) {
        _updateRemoteMessageStatus(data.messageId, MessageStatus.read);
        return;
      }
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.userId,
          category: data.category,
          content: plain,
          status: messageStatus,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message);
    } else if (data.category.endsWith('_POST')) {
      String plain;
      if (data.category == MessageCategory.signalPost) {
        plain = 'SignalPost';
      } else {
        plain = utf8.decode(base64.decode(plainText));
      }
      final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.userId,
        category: data.category,
        content: plain,
        status: messageStatus,
        createdAt: data.createdAt,
      );
      await database.messagesDao.insert(message);
    }

    _updateRemoteMessageStatus(data.messageId, messageStatus);
  }

  void _updateRemoteMessageStatus(messageId, MessageStatus status) {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    final blazeMessage = BlazeAckMessage(
        messageId: messageId, status: EnumToString.convertToString(status));
    database.jobsDao.insert(Job(
        jobId: Uuid().v4(),
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: jsonEncode(blazeMessage),
        createdAt: DateTime.now(),
        runCount: 0));
  }
}
