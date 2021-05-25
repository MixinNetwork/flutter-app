import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../blaze/vo/attachment_message.dart';
import '../blaze/vo/contact_message.dart';
import '../blaze/vo/recall_message.dart';
import '../blaze/vo/sticker_message.dart';
import '../constants/constants.dart';
import '../db/dao/jobs_dao.dart';
import '../db/dao/messages_dao.dart';
import '../db/extension/message.dart' show QueteMessage;
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
import '../enum/media_status.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../utils/attachment_util.dart';
import '../utils/load_balancer_utils.dart';

const _kEnableImageBlurHashThumb = false;

class SendMessageHelper {
  SendMessageHelper(this._messagesDao, this._jobsDao, this._attachmentUtil);

  final MessagesDao _messagesDao;
  final JobsDao _jobsDao;
  final AttachmentUtil _attachmentUtil;

  Future<void> sendTextMessage(
    String conversationId,
    String senderId,
    bool isPlain,
    String content, {
    String? quoteMessageId,
  }) async {
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
    final imageInfo = findDecoderForData(bytes)?.startDecode(bytes);

    final imageWidth = imageInfo!.width;
    final imageHeight = imageInfo.height;

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
      mediaWidth: imageWidth,
      mediaHeight: imageHeight,
      thumbImage: null,
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.pending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messagesDao.insert(message, senderId);
    final thumbImage =
        await runLoadBalancer(_getImageThumbnailString, file.path);

    final attachmentResult =
        await _attachmentUtil.uploadAttachment(attachment, messageId, category);
    if (attachmentResult == null) return;
    final attachmentMessage = AttachmentMessage(
        attachmentResult.keys,
        attachmentResult.digest,
        attachmentResult.attachmentId,
        mimeType,
        attachmentSize,
        null,
        imageWidth,
        imageHeight,
        thumbImage,
        null,
        null,
        null);

    final encoded = await runLoadBalancer(_encode, attachmentMessage);
    await _messagesDao.updateMessageContent(messageId, encoded);
    await _jobsDao.insertSendingJob(messageId, conversationId);
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
    final attachmentResult =
        await _attachmentUtil.uploadAttachment(attachment, messageId, category);
    if (attachmentResult == null) return;
    final attachmentMessage = AttachmentMessage(
        attachmentResult.keys,
        attachmentResult.digest,
        attachmentResult.attachmentId,
        mimeType,
        attachmentSize,
        file.name,
        null,
        null,
        null,
        null,
        null,
        null);

    final encoded = await runLoadBalancer(_encode, attachmentMessage);
    await _messagesDao.updateMessageContent(messageId, encoded);
    await _jobsDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> sendStickerMessage(String conversationId, String senderId,
      StickerMessage stickerMessage, MessageCategory category) async {
    final encoded = await runLoadBalancer(_encode, stickerMessage);

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
    final attachmentResult =
        await _attachmentUtil.uploadAttachment(attachment, messageId, category);
    if (attachmentResult == null) return;
    final attachmentMessage = AttachmentMessage(
        attachmentResult.keys,
        attachmentResult.digest,
        attachmentResult.attachmentId,
        mimeType,
        attachmentSize,
        file.name,
        null,
        null,
        null,
        null,
        null,
        null);

    final encoded = await runLoadBalancer(_encode, attachmentMessage);
    await _messagesDao.updateMessageContent(messageId, encoded);
    await _jobsDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> sendContactMessage(
    String conversationId,
    String senderId,
    ContactMessage contactMessage,
    String shareUserFullName, {
    bool isPlain = true,
    String? quoteMessageId,
  }) async {
    final category =
        isPlain ? MessageCategory.plainContact : MessageCategory.signalContact;
    final encoded = await runLoadBalancer(_encode, contactMessage);

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
    final attachmentResult =
        await _attachmentUtil.uploadAttachment(attachment, messageId, category);
    if (attachmentResult == null) return;
    final attachmentMessage = AttachmentMessage(
        attachmentResult.keys,
        attachmentResult.digest,
        attachmentResult.attachmentId,
        mimeType,
        attachmentSize,
        file.name,
        null,
        null,
        null,
        null,
        null,
        null);

    final encoded = await runLoadBalancer(_encode, attachmentMessage);
    await _messagesDao.updateMessageContent(messageId, encoded);
    await _jobsDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> _sendLiveMessage(
      String conversationId,
      String senderId,
      String content,
      String mediaUrl,
      String thumbImage,
      int mediaWidth,
      int mediaHeight,
      bool isPlain) async {
    final category =
        isPlain ? MessageCategory.plainLive : MessageCategory.signalLive;
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      mediaUrl: mediaUrl,
      thumbImage: thumbImage,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
    );

    await _messagesDao.insert(message, senderId);
    await _jobsDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> _sendPostMessage(String conversationId, String senderId,
      String content, bool isPlain) async {
    final category =
        isPlain ? MessageCategory.plainPost : MessageCategory.signalPost;
    final message = Message(
      messageId: const Uuid().v4(),
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

  Future<void> _sendLocationMessage(String conversationId, String senderId,
      String content, bool isPlain) async {
    final category = isPlain
        ? MessageCategory.plainLocation
        : MessageCategory.signalLocation;
    final message = Message(
      messageId: const Uuid().v4(),
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

  Future<void> _sendAppCardMessage(
      String conversationId, String senderId, String content) async {
    const category = MessageCategory.appCard;
    final message = Message(
      messageId: const Uuid().v4(),
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

  Future<void> sendRecallMessage(
      String conversationId, List<String> messageIds) async {
    messageIds.forEach((messageId) async {
      await _jobsDao.insert(Job(
          conversationId: conversationId,
          jobId: const Uuid().v4(),
          action: recallMessage,
          priority: 5,
          blazeMessage: await jsonEncodeWithIsolate(RecallMessage(messageId)),
          createdAt: DateTime.now(),
          runCount: 0));
      await _messagesDao.recallMessage(messageId);
    });
  }

  Future<void> forwardMessage(
    String conversationId,
    String senderId,
    String forwardMessageId, {
    bool isPlain = true,
  }) async {
    final message = await _messagesDao.findMessageByMessageId(forwardMessageId);
    if (message == null) {
      return;
    } else if (message.category.isText) {
      await sendTextMessage(
        conversationId,
        senderId,
        isPlain,
        message.content!,
      );
    } else if (message.category.isImage) {
      await sendImageMessage(
          conversationId,
          senderId,
          XFile(message.mediaUrl!),
          isPlain ? MessageCategory.plainImage : MessageCategory.signalImage,
          null);
    } else if (message.category.isVideo) {
      await sendVideoMessage(
          conversationId,
          senderId,
          XFile(message.mediaUrl!),
          isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo,
          null);
    } else if (message.category.isAudio) {
      await sendAudioMessage(
          conversationId,
          senderId,
          XFile(message.mediaUrl!),
          isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio,
          null);
    } else if (message.category.isData) {
      await sendVideoMessage(
          conversationId,
          senderId,
          XFile(message.mediaUrl!),
          isPlain ? MessageCategory.plainData : MessageCategory.signalData,
          null);
    } else if (message.category.isSticker) {
      await sendStickerMessage(
          conversationId,
          senderId,
          StickerMessage(message.stickerId!, null, null),
          isPlain
              ? MessageCategory.plainSticker
              : MessageCategory.signalSticker);
    } else if (message.category.isContact) {
      await sendContactMessage(
        conversationId,
        senderId,
        ContactMessage(message.sharedUserId!),
        message.name!,
        isPlain: isPlain,
      );
    } else if (message.category.isLive) {
      await _sendLiveMessage(
          conversationId,
          senderId,
          message.content!,
          message.mediaUrl!,
          message.thumbImage!,
          message.mediaWidth!,
          message.mediaHeight!,
          isPlain);
    } else if (message.category.isPost) {
      await _sendPostMessage(
          conversationId, senderId, message.content!, isPlain);
    } else if (message.category.isLocation) {
      await _sendLocationMessage(
          conversationId, senderId, message.content!, isPlain);
    } else if (message.category == MessageCategory.appCard) {
      await _sendAppCardMessage(conversationId, senderId, message.content!);
    }
  }

  Future<void> reUploadAttachment(
      String conversationId,
      String messageId,
      MessageCategory category,
      File file,
      String? name,
      String mediaMimeType,
      int mediaSize,
      int? mediaWidth,
      int? mediaHeight,
      String? thumbImage,
      String? mediaDuration,
      dynamic mediaWaveform) async {
    final attachmentResult =
        await _attachmentUtil.uploadAttachment(file, messageId, category);
    if (attachmentResult == null) return;
    final duration = mediaDuration != null ? int.parse(mediaDuration) : null;
    final attachmentMessage = AttachmentMessage(
        attachmentResult.keys,
        attachmentResult.digest,
        attachmentResult.attachmentId,
        mediaMimeType,
        mediaSize,
        name,
        mediaWidth,
        mediaHeight,
        thumbImage,
        duration,
        mediaWaveform,
        null);
    final encoded = await runLoadBalancer(_encode, attachmentMessage);
    await _messagesDao.updateMessageContent(messageId, encoded);
    await _jobsDao.insertSendingJob(messageId, conversationId);
  }
}

Future<String?> _getImageThumbnailString(String path) async {
  final image = decodeImage(await XFile(path).readAsBytes())!;
  String? thumbImage;
  if (_kEnableImageBlurHashThumb) {
    thumbImage = BlurHash.encode(image).hash;
  } else {
    final scale = max(max(image.width, image.height) / 48, 1.0);
    final thumbnail = copyResize(
      image,
      width: image.width ~/ scale,
      height: image.height ~/ scale,
    );
    thumbImage = base64Encode(encodeJpg(thumbnail, quality: 50));
  }
  return thumbImage;
}

String _encode(Object object) => base64Encode(utf8.encode(jsonEncode(object)));
