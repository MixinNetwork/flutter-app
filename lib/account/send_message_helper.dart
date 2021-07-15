import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:file_selector/file_selector.dart';
import 'package:image/image.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../blaze/vo/recall_message.dart';
import '../constants/constants.dart';
import '../db/dao/job_dao.dart';
import '../db/dao/message_dao.dart';
import '../db/dao/message_mention_dao.dart';
import '../db/dao/participant_dao.dart';
import '../db/extension/message.dart' show QueteMessage;
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
import '../enum/media_status.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../utils/attachment_util.dart';
import '../utils/datetime_format_utils.dart';
import '../utils/file.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/reg_exp_utils.dart';

const _kEnableImageBlurHashThumb = true;

class SendMessageHelper {
  SendMessageHelper(
    this._messageDao,
    this._messageMentionDao,
    this._jobDao,
    this._participantDao,
    this._attachmentUtil,
  );

  final MessageDao _messageDao;
  final MessageMentionDao _messageMentionDao;
  final ParticipantDao _participantDao;
  final JobDao _jobDao;
  final AttachmentUtil _attachmentUtil;

  Future<void> sendTextMessage(
    String conversationId,
    String senderId,
    bool isPlain,
    String content, {
    String? quoteMessageId,
  }) async {
    var category =
        isPlain ? MessageCategory.plainText : MessageCategory.signalText;
    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);

    String? recipientId;
    final botNumber = botNumberStartRegExp.firstMatch(content)?[1];
    if (botNumber?.isNotEmpty == true) {
      recipientId = await _participantDao
          .userIdByIdentityNumber(conversationId, botNumber!)
          .getSingleOrNull();
      category = recipientId != null ? MessageCategory.plainText : category;
    }

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

    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(
      message.messageId,
      conversationId,
      recipientId,
    );
  }

  Future<void> sendImageMessage({
    required String conversationId,
    required String senderId,
    XFile? file,
    Uint8List? bytes,
    required String category,
    String? quoteMessageId,
    AttachmentResult? attachmentResult,
  }) async {
    final messageId = const Uuid().v4();
    final mimeType =
        file?.mimeType ?? lookupMimeType(file?.path ?? '') ?? 'image/jpeg';

    var attachment = _attachmentUtil.getAttachmentFile(
      category,
      conversationId,
      messageId,
      mimeType: mimeType,
    );

    final _bytes = bytes ?? await file!.readAsBytes();

    // Only retrieve image bounds info.
    final imageInfo = findDecoderForData(_bytes)?.startDecode(_bytes);

    final imageWidth = imageInfo!.width;
    final imageHeight = imageInfo.height;

    attachment = await attachment.create(recursive: true);

    await attachment.writeAsBytes(_bytes.toList());

    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);
    final fileName = file?.name ?? '$messageId.png';
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.pathBasename,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      mediaWidth: imageWidth,
      mediaHeight: imageHeight,
      thumbImage: null,
      name: fileName,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messageDao.insert(message, senderId);
    final thumbImage = await runLoadBalancer(
      _getImageThumbnailString,
      attachment.path,
    );
    // ignore: parameter_assignments
    attachmentResult ??=
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
      null,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
        messageId, encoded);
    await _jobDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> sendVideoMessage(String conversationId, String senderId,
      XFile file, String category, String? quoteMessageId,
      {AttachmentResult? attachmentResult}) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'video/mp4';
    final attachment = _attachmentUtil.getAttachmentFile(
        category, conversationId, messageId,
        mimeType: mimeType);
    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.pathBasename,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      // mediaWidth: , // todo
      // mediaHeight: ,// todo
      // thumbImage: , //todo
      // mediaDuration: , // todo
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messageDao.insert(message, senderId);
    // ignore: parameter_assignments
    attachmentResult ??=
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
      null,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
        messageId, encoded);
    await _jobDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> sendStickerMessage(String conversationId, String senderId,
      StickerMessage stickerMessage, String category) async {
    final encoded = await jsonBase64EncodeWithIsolate(stickerMessage);

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

    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendDataMessage(
    String conversationId,
    String senderId,
    XFile file,
    String category,
    String? quoteMessageId, {
    AttachmentResult? attachmentResult,
    String? name,
  }) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ??
        lookupMimeType(file.path) ??
        'application/octet-stream';
    final attachment = _attachmentUtil.getAttachmentFile(
        category, conversationId, messageId,
        mimeType: mimeType);

    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.pathBasename,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      name: name ?? file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messageDao.insert(message, senderId);
    // ignore: parameter_assignments
    attachmentResult ??=
        await _attachmentUtil.uploadAttachment(attachment, messageId, category);
    if (attachmentResult == null) return;
    final attachmentMessage = AttachmentMessage(
      attachmentResult.keys,
      attachmentResult.digest,
      attachmentResult.attachmentId,
      mimeType,
      attachmentSize,
      name ?? file.name,
      null,
      null,
      null,
      null,
      null,
      null,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
        messageId, encoded);
    await _jobDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> sendContactMessage(
    String conversationId,
    String senderId,
    ContactMessage contactMessage,
    String? shareUserFullName, {
    bool isPlain = true,
    String? quoteMessageId,
  }) async {
    final category =
        isPlain ? MessageCategory.plainContact : MessageCategory.signalContact;
    final encoded = await jsonBase64EncodeWithIsolate(contactMessage);

    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);
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
    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendAudioMessage(String conversationId, String senderId,
      XFile file, String category, String? quoteMessageId,
      {AttachmentResult? attachmentResult}) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'audio/ogg';
    final attachment = _attachmentUtil.getAttachmentFile(
        category, conversationId, messageId,
        mimeType: mimeType);

    await attachment.create(recursive: true);
    await File(file.path).copy(attachment.path);
    final attachmentSize = await attachment.length();
    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      content: '',
      category: category,
      mediaUrl: attachment.pathBasename,
      mediaMimeType: mimeType,
      mediaSize: await attachment.length(),
      // mediaDuration: , // todo
      // waveForm: , // todo
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _messageDao.insert(message, senderId);
    // ignore: parameter_assignments
    attachmentResult ??=
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
      null,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
        messageId, encoded);
    await _jobDao.insertSendingJob(messageId, conversationId);
  }

  Future<void> _sendLiveMessage(
      String conversationId,
      String senderId,
      String content,
      String mediaUrl,
      String thumbUrl,
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
      thumbUrl: thumbUrl,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
    );

    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendPostMessage(String conversationId, String senderId,
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

    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(message.messageId, conversationId);
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

    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(message.messageId, conversationId);
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

    await _messageDao.insert(message, senderId);
    await _jobDao.insertSendingJob(message.messageId, conversationId);
  }

  Future<void> sendRecallMessage(
      String conversationId, List<String> messageIds) async {
    messageIds.forEach((messageId) async {
      final message = await _messageDao.findMessageByMessageId(messageId);
      if (message?.category.isAttachment == true) {
        final file = File(message!.mediaUrl!);
        final exists = await file.exists();
        if (exists) {
          await file.delete();
        }
      }
      await _messageDao.recallMessage(messageId);
      await _messageMentionDao.deleteMessageMentionByMessageId(messageId);
      final quoteMessage =
          await _messageDao.findMessageItemById(conversationId, messageId);
      if (quoteMessage != null) {
        await _messageDao.updateQuoteContentByQuoteId(
            conversationId, messageId, quoteMessage.toJson());
      }
      await _jobDao.insert(Job(
          conversationId: conversationId,
          jobId: const Uuid().v4(),
          action: recallMessage,
          priority: 5,
          blazeMessage: await jsonEncodeWithIsolate(RecallMessage(messageId)),
          createdAt: DateTime.now(),
          runCount: 0));
      await _messageDao.recallMessage(messageId);
      await _messageDao.deleteFtsByMessageId(messageId);
    });
  }

  Future<void> forwardMessage(
    String conversationId,
    String senderId,
    String forwardMessageId, {
    bool isPlain = true,
  }) async {
    final message = await _messageDao.findMessageByMessageId(forwardMessageId);
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
      final category =
          isPlain ? MessageCategory.plainImage : MessageCategory.signalImage;
      AttachmentResult? attachmentResult;
      if (message.category == category && message.content != null) {
        attachmentResult = await _checkAttachment(message.content!);
      } else {
        attachmentResult = null;
      }
      await sendImageMessage(
        conversationId: conversationId,
        senderId: senderId,
        file: XFile(message.mediaUrl!),
        category: category,
        quoteMessageId: null,
        attachmentResult: attachmentResult,
      );
    } else if (message.category.isVideo) {
      final category =
          isPlain ? MessageCategory.plainData : MessageCategory.signalData;
      AttachmentResult? attachmentResult;
      if (message.category == category && message.content != null) {
        attachmentResult = await _checkAttachment(message.content!);
      } else {
        attachmentResult = null;
      }
      await sendDataMessage(
        conversationId,
        senderId,
        XFile(message.mediaUrl!),
        category,
        null,
        attachmentResult: attachmentResult,
      );
    } else if (message.category.isAudio) {
      final category =
          isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio;
      AttachmentResult? attachmentResult;
      if (message.category == category && message.content != null) {
        attachmentResult = await _checkAttachment(message.content!);
      } else {
        attachmentResult = null;
      }
      await sendAudioMessage(
        conversationId,
        senderId,
        XFile(message.mediaUrl!),
        category,
        null,
        attachmentResult: attachmentResult,
      );
    } else if (message.category.isData) {
      final category =
          isPlain ? MessageCategory.plainData : MessageCategory.signalData;
      AttachmentResult? attachmentResult;
      if (message.category == category && message.content != null) {
        attachmentResult = await _checkAttachment(message.content!);
      } else {
        attachmentResult = null;
      }

      await sendDataMessage(
        conversationId,
        senderId,
        XFile(message.mediaUrl!),
        category,
        null,
        attachmentResult: attachmentResult,
        name: message.name,
      );
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
        message.name,
        isPlain: isPlain,
      );
    } else if (message.category.isLive) {
      final liveMessage = LiveMessage(
          message.mediaWidth!,
          message.mediaHeight!,
          // TODO shareable?
          message.thumbUrl ?? '',
          message.mediaUrl!,
          true);
      final encoded = await jsonBase64EncodeWithIsolate(liveMessage);
      await _sendLiveMessage(
          conversationId,
          senderId,
          encoded,
          message.mediaUrl!,
          message.thumbUrl ?? '',
          message.mediaWidth!,
          message.mediaHeight!,
          isPlain);
    } else if (message.category.isPost) {
      await sendPostMessage(
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
    String category,
    File file,
    String? name,
    String mediaMimeType,
    int mediaSize,
    int? mediaWidth,
    int? mediaHeight,
    String? thumbImage,
    String? mediaDuration,
    dynamic mediaWaveform,
    String? content,
  ) async {
    AttachmentResult? attachmentResult;
    if (content != null) {
      attachmentResult = await _checkAttachment(content);
    }
    attachmentResult ??=
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
      null,
      attachmentResult.createdAt,
    );
    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
        messageId, encoded);
    await _jobDao.insertSendingJob(messageId, conversationId);
  }

  Future<AttachmentResult?> _checkAttachment(String content) async {
    AttachmentMessage? attachmentMessage;
    try {
      attachmentMessage = AttachmentMessage.fromJson(
          await jsonBase64DecodeWithIsolate(content));
    } catch (e) {
      attachmentMessage = null;
    }
    if (attachmentMessage == null) {
      return null;
    }
    final createdAt = attachmentMessage.createdAt;
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (within24Hours(date)) {
        return AttachmentResult(
          attachmentMessage.attachmentId,
          attachmentMessage.key,
          attachmentMessage.digest,
          attachmentMessage.createdAt,
        );
      }
    }
    return null;
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
