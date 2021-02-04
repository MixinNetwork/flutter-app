import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_app/blaze/vo/attachment_message.dart';
import 'package:flutter_app/blaze/vo/contact_message.dart';
import 'package:flutter_app/blaze/vo/sticker_message.dart';
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

  // ignore: unused_field
  final AttachmentUtil _attachmentUtil;

  void sendTextMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    final category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
    final message = Message(
      messageId: Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  void sendImageMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainImage : MessageCategory.signalImage;
  }

  void sendVideoMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo;
  }

  Future<void> sendStickerMessage(
    String conversationId,
    String senderId,
    StickerMessage stickerMessage, {
    bool isPlain = true,
  }) async {
    final category =
        isPlain ? MessageCategory.plainSticker : MessageCategory.signalSticker;

    final encoded = base64.encode(utf8.encode(jsonEncode(stickerMessage)));
    final message = Message(
      messageId: Uuid().v4(),
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

  void sendDataMessage(
      String conversationId, String senderId, XFile file, bool isPlain) async {
    final messageId = Uuid().v4();
    final mimeType = file.mimeType ??
        lookupMimeType(file.path) ??
        'application/octet-stream';
    final attachment = _attachmentUtil.getAttachmentFile(
        MessageCategory.plainData, conversationId, messageId);
    // ignore: cascade_invocations
    attachment.createSync(recursive: true);
    File(file.path).copySync(attachment.path);
    final attachmentSize = await attachment.length();
    final category =
        isPlain ? MessageCategory.plainData : MessageCategory.signalData;
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
    );
    await _messagesDao.insert(message, senderId);
    await _attachmentUtil
        .uploadAttachment(attachment, messageId)
        .then((attachmentId) async {
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
      bool isPlain) async {
    final category =
        isPlain ? MessageCategory.plainContact : MessageCategory.signalContact;
    final encoded = base64.encode(utf8.encode(jsonEncode(contactMessage)));
    final message = Message(
      messageId: Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: encoded,
      sharedUserId: contactMessage.userId,
      name: shareUserFullName,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  void sendAudioMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio;
  }

  void sendLiveMessage(String conversationId, String senderId, String content,
      bool isPlain) async {
    // ignore: unused_local_variable
    final category =
        isPlain ? MessageCategory.plainLive : MessageCategory.signalLive;
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
