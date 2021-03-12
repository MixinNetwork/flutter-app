import 'dart:convert';
import 'dart:io';
import 'package:flutter_app/utils/load_balancer_utils.dart';
import 'package:image/image.dart';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_app/blaze/vo/attachment_message.dart';
import 'package:flutter_app/blaze/vo/contact_message.dart';
import 'package:flutter_app/blaze/vo/sticker_message.dart';
import 'package:flutter_app/db/extension/message.dart' show QueteMessage;
import 'package:flutter_app/db/dao/jobs_dao.dart';
import 'package:flutter_app/db/dao/messages_dao.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/media_status.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/utils/attachment_util.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

class SendMessageHelper {
  SendMessageHelper(this._messagesDao, this._jobsDao, this._attachmentUtil);

  final MessagesDao _messagesDao;
  final JobsDao _jobsDao;
  final AttachmentUtil _attachmentUtil;

  Future<void> sendTextMessage(String conversationId, String senderId,
      String content, bool isPlain, String? quoteMessageId) async {
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: content,
      status: MessageStatus.sending,
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
      createdAt: DateTime.now(),
    );

    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendImageMessage(String conversationId, String senderId,
      XFile file, MessageCategory category, String? quoteMessageId) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'image/jpeg';
    final attachment =
        _attachmentUtil.getAttachmentFile(category, conversationId, messageId);
    final bytes = await file.readAsBytes();
    final image = decodeImage(bytes);
    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.path,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      mediaWidth: image!.width,
      mediaHeight: image.height,
      // thumbImage: , // todo
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messagesDao.insert(message, senderId);
    await _attachmentUtil
        .uploadAttachment(attachment, messageId)
        .then((attachmentId) async {
      if (attachmentId == null) return;
      final attachmentMessage = AttachmentMessage(
          null,
          null,
          attachmentId,
          mimeType,
          attachmentSize,
          null,
          image.width,
          image.height,
          null,
          null,
          null,
          null);

      final encoded = base64.encode(utf8.encode(jsonEncode(attachmentMessage)));
      _messagesDao.updateMessageContent(messageId, encoded);
      await _jobsDao.insertSendingJob(messageId, conversationId);
    });
  }

  Future<void> sendVideoMessage(String conversationId, String senderId,
      XFile file, MessageCategory category, String? quoteMessageId) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'video/mp4';
    final attachment =
        _attachmentUtil.getAttachmentFile(category, conversationId, messageId);
    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.path,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      // mediaWidth: , // todo
      // mediaHeight: ,// todo
      // thumbImage: , //todo
      // mediaDuration: , // todo
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messagesDao.insert(message, senderId);
    await _attachmentUtil
        .uploadAttachment(attachment, messageId)
        .then((attachmentId) async {
      if (attachmentId == null) return;
      final attachmentMessage = AttachmentMessage(
          null,
          null,
          attachmentId,
          mimeType,
          attachmentSize,
          file.name,
          null,
          null,
          null,
          null,
          null,
          null);

      final encoded = base64.encode(utf8.encode(jsonEncode(attachmentMessage)));
      _messagesDao.updateMessageContent(messageId, encoded);
      await _jobsDao.insertSendingJob(messageId, conversationId);
    });
  }

  Future<void> sendStickerMessage(String conversationId, String senderId,
      StickerMessage stickerMessage, MessageCategory category) async {
    final encoded = base64.encode(utf8.encode(jsonEncode(stickerMessage)));
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: encoded,
      stickerId: stickerMessage.stickerId,
      albumId: stickerMessage.albumId,
      name: stickerMessage.name,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendDataMessage(String conversationId, String senderId,
      XFile file, MessageCategory category, String? quoteMessageId) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ??
        lookupMimeType(file.path) ??
        'application/octet-stream';
    final attachment =
        _attachmentUtil.getAttachmentFile(category, conversationId, messageId);

    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.path,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messagesDao.insert(message, senderId);
    await _attachmentUtil
        .uploadAttachment(attachment, messageId)
        .then((attachmentId) async {
      if (attachmentId == null) return;
      final attachmentMessage = AttachmentMessage(
          null,
          null,
          attachmentId,
          mimeType,
          attachmentSize,
          file.name,
          null,
          null,
          null,
          null,
          null,
          null);

      final encoded = base64.encode(utf8.encode(jsonEncode(attachmentMessage)));
      _messagesDao.updateMessageContent(messageId, encoded);
      await _jobsDao.insertSendingJob(messageId, conversationId);
    });
  }

  void sendContactMessage(
      String conversationId,
      String senderId,
      ContactMessage contactMessage,
      String shareUserFullName,
      bool isPlain,
      String? quoteMessageId) async {
    final category =
        isPlain ? MessageCategory.plainContact : MessageCategory.signalContact;
    final encoded = base64.encode(utf8.encode(jsonEncode(contactMessage)));
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: encoded,
      sharedUserId: contactMessage.userId,
      name: shareUserFullName,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendAudioMessage(String conversationId, String senderId,
      XFile file, MessageCategory category, String? quoteMessageId) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'video/mp4';
    final attachment =
        _attachmentUtil.getAttachmentFile(category, conversationId, messageId);

    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.path,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      // mediaDuration: , // todo
      // waveForm: , // todo
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messagesDao.insert(message, senderId);
    await _attachmentUtil
        .uploadAttachment(attachment, messageId)
        .then((attachmentId) async {
      if (attachmentId == null) return;
      final attachmentMessage = AttachmentMessage(
          null,
          null,
          attachmentId,
          mimeType,
          attachmentSize,
          file.name,
          null,
          null,
          null,
          null,
          null,
          null);

      final encoded = base64.encode(utf8.encode(jsonEncode(attachmentMessage)));
      _messagesDao.updateMessageContent(messageId, encoded);
      await _jobsDao.insertSendingJob(messageId, conversationId);
    });
  }

  void sendLiveMessage(String conversationId, String senderId, String content,
      bool isPlain, String? quoteMessageId) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainLive : MessageCategory.signalLive;
    // ignore: unused_local_variable
    final quoteMessage =
        await _messagesDao.findMessageItemByMessageId(quoteMessageId);
  }

  void sendPostMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainPost : MessageCategory.signalPost;
  }

  void sendLocationMessage(String conversationId, String senderId,
      String content, bool isPlain) async {
    // ignore: unused_local_variable
    final category = isPlain
        ? MessageCategory.plainLocation
        : MessageCategory.signalLocation;
  }

  void sendAppCardMessage(
      String conversationId, String senderId, String content, bool isPlain) {
    // ignore: unused_local_variable
    const category = MessageCategory.appCard;
  }

  void sendAppButtonGroup(
      String conversationId, String senderId, String content, bool isPlain) {
    // ignore: unused_local_variable
    const category = MessageCategory.appButtonGroup;
  }
}
