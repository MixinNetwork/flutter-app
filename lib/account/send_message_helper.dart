import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:drift/drift.dart';
import 'package:mime/mime.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../blaze/vo/pin_message_minimal.dart';
import '../blaze/vo/pin_message_payload.dart';
import '../blaze/vo/transcript_minimal.dart';
import '../db/dao/job_dao.dart';
import '../db/dao/message_dao.dart';
import '../db/dao/message_mention_dao.dart';
import '../db/dao/participant_dao.dart';
import '../db/dao/pin_message_dao.dart';
import '../db/dao/transcript_message_dao.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart';
import '../enum/encrypt_category.dart';
import '../enum/media_status.dart';
import '../enum/message_category.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/extension/extension.dart';
import '../utils/image.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/reg_exp_utils.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import '../widgets/message/send_message_dialog/attachment_extra.dart';
import '../widgets/mixin_image.dart';
import 'show_pin_message_key_value.dart';

const jpegMimeType = 'image/jpeg';
const gifMimeType = 'image/gif';

class SendMessageHelper {
  SendMessageHelper(
    this._database,
    this._attachmentUtil,
    this._addSendingJob,
  );

  final Database _database;
  late final MessageDao _messageDao = _database.messageDao;
  late final MessageMentionDao _messageMentionDao = _database.messageMentionDao;
  late final ParticipantDao _participantDao = _database.participantDao;
  late final JobDao _jobDao = _database.jobDao;
  late final PinMessageDao _pinMessageDao = _database.pinMessageDao;

  late final TranscriptMessageDao _transcriptMessageDao =
      _database.transcriptMessageDao;
  final AttachmentUtil _attachmentUtil;
  final Function(Job) _addSendingJob;

  Future<void> _insertSendMessageToDb(
    Message message, {
    String? ftsContent,
    bool cleanDraft = true,
  }) async {
    final conversationId = message.conversationId;
    final conversation = await _database.conversationDao
        .conversationItem(conversationId)
        .getSingleOrNull();
    assert(conversation != null, 'no conversation');
    final expireIn = conversation?.expireIn ?? 0;
    await _messageDao.insert(
      message,
      message.userId,
      expireIn: expireIn,
      cleanDraft: cleanDraft,
    );
    unawaited(_database.ftsDatabase.insertFts(message, ftsContent));
  }

  Future<void> sendTextMessage(
    String conversationId,
    String senderId,
    EncryptCategory encryptCategory,
    String content, {
    String? quoteMessageId,
    bool silent = false,
    bool cleanDraft = true,
  }) async {
    var category = encryptCategory.toCategory(MessageCategory.plainText,
        MessageCategory.signalText, MessageCategory.encryptedText);
    final quoteMessage =
        await _messageDao.findMessageItemByMessageId(quoteMessageId);

    String? recipientId;

    if (content.startsWith('@7000')) {
      final botNumber = botNumberRegExp.firstMatch(content)?[0];
      if (botNumber != null && botNumber.isNotEmpty) {
        recipientId = await _participantDao
            .userIdByIdentityNumber(conversationId, botNumber)
            .getSingleOrNull();
        category = recipientId != null ? MessageCategory.plainText : category;
      }
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

    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(await _jobDao.createSendingJob(
      message.messageId,
      conversationId,
      recipientId: recipientId,
      silent: silent,
    ));
  }

  Future<void> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String category,
    XFile? file,
    Uint8List? bytes,
    String? quoteMessageId,
    AttachmentResult? attachmentResult,
    bool silent = false,
    bool cleanDraft = true,
    bool compress = false,
    String? caption,
  }) async {
    final messageId = const Uuid().v4();

    var _bytes = bytes ?? await file?.readAsBytes();
    if (_bytes == null) throw Exception('file is null');

    final int imageWidth;
    final int imageHeight;
    final String mimeType;
    final String fileName;

    if (compress) {
      final result = await compressWithIsolate(_bytes);
      if (result == null) throw Exception('compress failed');
      final ImageType type;
      (_bytes, type, imageWidth, imageHeight) = result;
      mimeType = type.mimeType;
      fileName =
          '${file?.name.pathBasenameWithoutExtension ?? messageId}.${type.extension}';
    } else {
      mimeType = file?.mimeType ??
          lookupMimeType(file?.path ?? '',
              headerBytes:
                  _bytes.take(defaultMagicNumbersMaxLength).toList()) ??
          'image/jpeg';
      // Only retrieve image bounds info.
      final buffer = await ui.ImmutableBuffer.fromUint8List(_bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);

      imageWidth = descriptor.width;
      imageHeight = descriptor.height;
      fileName = file?.name ?? '$messageId.${extensionFromMime(mimeType)}';
    }

    var attachment = _attachmentUtil.getAttachmentFile(
      category,
      conversationId,
      messageId,
      file?.name,
      mimeType: mimeType,
    );

    attachment = await attachment.create(recursive: true);

    await attachment.writeAsBytes(_bytes.toList());
    final thumbImage = await attachment.encodeBlurHash();

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
      mediaSize: attachmentSize,
      mediaWidth: imageWidth,
      mediaHeight: imageHeight,
      name: fileName,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
      thumbImage: thumbImage,
      caption: caption,
    );
    await _insertSendMessageToDb(
      message,
      cleanDraft: cleanDraft,
      ftsContent: caption,
    );

    if (await _attachmentUtil.isNotPending(messageId)) return;

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
      caption,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
      messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(messageId, conversationId,
        silent: silent));
  }

  Future<void> sendVideoMessage(
    String conversationId,
    String senderId,
    XFile file,
    String category,
    String? quoteMessageId, {
    AttachmentResult? attachmentResult,
    int? mediaWidth,
    int? mediaHeight,
    String? thumbImage,
    String? mediaDuration,
    bool silent = false,
    bool cleanDraft = true,
  }) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'video/mp4';
    final attachment = _attachmentUtil.getAttachmentFile(
      category,
      conversationId,
      messageId,
      file.name,
      mimeType: mimeType,
    );
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
      mediaSize: attachmentSize,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      thumbImage: thumbImage,
      mediaDuration: mediaDuration,
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
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
      mediaWidth,
      mediaHeight,
      thumbImage,
      mediaDuration == null ? null : int.tryParse(mediaDuration),
      null,
      null,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
      messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(
      messageId,
      conversationId,
      silent: silent,
    ));
  }

  Future<void> sendStickerMessage(
    String conversationId,
    String senderId,
    StickerMessage stickerMessage,
    String category, {
    bool cleanDraft = true,
  }) async {
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

    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(
        await _jobDao.createSendingJob(message.messageId, conversationId));
  }

  Future<void> sendDataMessage(
    String conversationId,
    String senderId,
    XFile file,
    String category,
    String? quoteMessageId, {
    AttachmentResult? attachmentResult,
    String? name,
    bool silent = false,
    bool cleanDraft = true,
  }) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ??
        lookupMimeType(file.path) ??
        'application/octet-stream';
    final attachment = _attachmentUtil.getAttachmentFile(
      category,
      conversationId,
      messageId,
      file.name,
      mimeType: mimeType,
    );

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
      mediaSize: attachmentSize,
      name: name ?? file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
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
      messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(
      messageId,
      conversationId,
      silent: silent,
    ));
  }

  Future<void> sendContactMessage(
    String conversationId,
    String senderId,
    ContactMessage contactMessage,
    String? shareUserFullName, {
    EncryptCategory encryptCategory = EncryptCategory.plain,
    String? quoteMessageId,
    bool cleanDraft = true,
  }) async {
    final category = encryptCategory.toCategory(MessageCategory.plainContact,
        MessageCategory.signalContact, MessageCategory.encryptedContact);
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
    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(
        await _jobDao.createSendingJob(message.messageId, conversationId));
  }

  Future<void> sendAudioMessage(
    String conversationId,
    String senderId,
    XFile file,
    String category,
    String? quoteMessageId, {
    AttachmentResult? attachmentResult,
    String? mediaDuration,
    String? mediaWaveform,
    bool cleanDraft = true,
  }) async {
    final messageId = const Uuid().v4();
    final mimeType = file.mimeType ?? lookupMimeType(file.path) ?? 'audio/ogg';
    final attachment = _attachmentUtil.getAttachmentFile(
      category,
      conversationId,
      messageId,
      file.name,
      mimeType: mimeType,
    );

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
      mediaSize: attachmentSize,
      mediaDuration: mediaDuration,
      mediaWaveform: mediaWaveform,
      name: file.name,
      mediaStatus: MediaStatus.pending,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      quoteMessageId: quoteMessageId,
      quoteContent: quoteMessage?.toJson(),
    );
    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
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
      int.tryParse(mediaDuration ?? ''),
      mediaWaveform,
      null,
      attachmentResult.createdAt,
    );

    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
      messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(messageId, conversationId));
  }

  Future<void> _sendLiveMessage(
    String conversationId,
    String senderId,
    String content,
    String mediaUrl,
    String thumbUrl,
    int mediaWidth,
    int mediaHeight,
    EncryptCategory encryptCategory, {
    bool cleanDraft = true,
  }) async {
    final category = encryptCategory.toCategory(MessageCategory.plainLive,
        MessageCategory.signalLive, MessageCategory.encryptedLive);
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

    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(
        await _jobDao.createSendingJob(message.messageId, conversationId));
  }

  Future<void> sendPostMessage(
    String conversationId,
    String senderId,
    String content,
    EncryptCategory encryptCategory, {
    bool cleanDraft = true,
  }) async {
    final category = encryptCategory.toCategory(MessageCategory.plainPost,
        MessageCategory.signalPost, MessageCategory.encryptedPost);
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(
        await _jobDao.createSendingJob(message.messageId, conversationId));
  }

  Future<void> _sendLocationMessage(
    String conversationId,
    String senderId,
    String content,
    EncryptCategory encryptCategory, {
    bool cleanDraft = true,
  }) async {
    final category = encryptCategory.toCategory(MessageCategory.plainLocation,
        MessageCategory.signalLocation, MessageCategory.encryptedLocation);
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(
        await _jobDao.createSendingJob(message.messageId, conversationId));
  }

  Future<void> sendAppCardMessage(
    String conversationId,
    String senderId,
    String content, {
    bool cleanDraft = true,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
      final card = AppCardData.fromJson(data);
      if (data['actions'] != null && !card.canShareActions) {
        data['actions'] = null;
      }
      if (data['action'] == '') {
        data['action'] = null;
      }
    } catch (e) {
      w('AppCardData.fromJson error: $e');
      return;
    }

    const category = MessageCategory.appCard;
    final message = Message(
      messageId: const Uuid().v4(),
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: jsonEncode(data),
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    await _insertSendMessageToDb(message, cleanDraft: cleanDraft);
    _addSendingJob(
        await _jobDao.createSendingJob(message.messageId, conversationId));
  }

  Future<void> sendRecallMessage(
    String conversationId,
    List<String> messageIds,
  ) async {
    await Future.wait(messageIds.map((messageId) async {
      final message = await _messageDao.findMessageByMessageId(messageId);

      await _messageDao.recallMessage(conversationId, messageId);

      unawaited(_database.ftsDatabase.deleteByMessageId(messageId));

      await Future.wait([
        (() async {
          if (message?.category.isAttachment == true) {
            final file = File(message!.mediaUrl!);
            final exists = file.existsSync();
            if (exists) {
              await file.delete();
            }
          }
        })(),
        _messageMentionDao.deleteMessageMention(MessageMention(
          messageId: messageId,
          conversationId: conversationId,
        )),
        (() async => _addSendingJob(
            await createSendRecallJob(conversationId, messageId)))(),
        (() async {
          final quoteMessage =
              await _messageDao.findMessageItemById(conversationId, messageId);

          if (quoteMessage != null) {
            await _messageDao.updateQuoteContentByQuoteId(
              conversationId,
              messageId,
              quoteMessage.toJson(),
            );
          }
        })(),
      ]);
    }));
  }

  Future<void> forwardMessage(
    String conversationId,
    String senderId,
    String forwardMessageId, {
    EncryptCategory encryptCategory = EncryptCategory.plain,
  }) async {
    final message = await _messageDao.findMessageByMessageId(forwardMessageId);
    if (message == null) {
      return;
    } else if (message.category.isText) {
      await sendTextMessage(
        conversationId,
        senderId,
        encryptCategory,
        message.content!,
        cleanDraft: false,
      );
    } else if (message.category.isImage) {
      final category = encryptCategory.toCategory(MessageCategory.plainImage,
          MessageCategory.signalImage, MessageCategory.encryptedImage);
      AttachmentResult? attachmentResult;
      attachmentResult = message.category == category
          ? await _checkAttachmentExtra(message)
          : null;
      await sendImageMessage(
        conversationId: conversationId,
        senderId: senderId,
        file: XFile(_attachmentUtil.convertAbsolutePath(
          category: message.category,
          conversationId: message.conversationId,
          fileName: message.mediaUrl,
        )),
        caption: message.caption,
        category: category,
        attachmentResult: attachmentResult,
        cleanDraft: false,
      );
    } else if (message.category.isVideo) {
      final category = encryptCategory.toCategory(MessageCategory.plainVideo,
          MessageCategory.signalVideo, MessageCategory.encryptedVideo);
      AttachmentResult? attachmentResult;
      attachmentResult = message.category == category
          ? await _checkAttachmentExtra(message)
          : null;
      await sendVideoMessage(
        conversationId,
        senderId,
        XFile(_attachmentUtil.convertAbsolutePath(
          category: message.category,
          conversationId: message.conversationId,
          fileName: message.mediaUrl,
        )),
        category,
        null,
        attachmentResult: attachmentResult,
        mediaDuration: message.mediaDuration,
        mediaHeight: message.mediaHeight,
        mediaWidth: message.mediaWidth,
        thumbImage: message.thumbImage,
        cleanDraft: false,
      );
    } else if (message.category.isAudio) {
      final category = encryptCategory.toCategory(MessageCategory.plainAudio,
          MessageCategory.signalAudio, MessageCategory.encryptedAudio);
      AttachmentResult? attachmentResult;
      attachmentResult = message.category == category
          ? await _checkAttachmentExtra(message)
          : null;
      await sendAudioMessage(
        conversationId,
        senderId,
        XFile(_attachmentUtil.convertAbsolutePath(
          category: message.category,
          conversationId: message.conversationId,
          fileName: message.mediaUrl,
        )),
        category,
        null,
        attachmentResult: attachmentResult,
        mediaDuration: message.mediaDuration,
        mediaWaveform: message.mediaWaveform,
        cleanDraft: false,
      );
    } else if (message.category.isData) {
      final category = encryptCategory.toCategory(MessageCategory.plainData,
          MessageCategory.signalData, MessageCategory.encryptedData);
      AttachmentResult? attachmentResult;
      attachmentResult = message.category == category
          ? await _checkAttachmentExtra(message)
          : null;

      await sendDataMessage(
        conversationId,
        senderId,
        XFile(_attachmentUtil.convertAbsolutePath(
          category: message.category,
          conversationId: message.conversationId,
          fileName: message.mediaUrl,
        )),
        category,
        null,
        attachmentResult: attachmentResult,
        name: message.name,
        cleanDraft: false,
      );
    } else if (message.category.isSticker) {
      await sendStickerMessage(
        conversationId,
        senderId,
        StickerMessage(message.stickerId!, null, null),
        encryptCategory.toCategory(MessageCategory.plainSticker,
            MessageCategory.signalSticker, MessageCategory.encryptedSticker),
        cleanDraft: false,
      );
    } else if (message.category.isContact) {
      await sendContactMessage(
        conversationId,
        senderId,
        ContactMessage(message.sharedUserId!),
        message.name,
        encryptCategory: encryptCategory,
        cleanDraft: false,
      );
    } else if (message.category.isLive) {
      var shareable = true;
      if (message.content != null) {
        try {
          final map = await jsonDecodeWithIsolate(message.content!);
          shareable =
              LiveMessage.fromJson(map as Map<String, dynamic>).shareable;
        } catch (_) {
          // ignore
        }
      }
      final liveMessage = LiveMessage(
        message.mediaWidth!,
        message.mediaHeight!,
        message.thumbUrl ?? '',
        message.mediaUrl!,
        shareable,
      );
      final encoded = await jsonEncodeWithIsolate(liveMessage);
      await _sendLiveMessage(
        conversationId,
        senderId,
        encoded,
        message.mediaUrl!,
        message.thumbUrl ?? '',
        message.mediaWidth!,
        message.mediaHeight!,
        encryptCategory,
        cleanDraft: false,
      );
    } else if (message.category.isPost) {
      await sendPostMessage(
        conversationId,
        senderId,
        message.content!,
        encryptCategory,
        cleanDraft: false,
      );
    } else if (message.category.isLocation) {
      await _sendLocationMessage(
        conversationId,
        senderId,
        message.content!,
        encryptCategory,
        cleanDraft: false,
      );
    } else if (message.category == MessageCategory.appCard) {
      await sendAppCardMessage(
        conversationId,
        senderId,
        message.content!,
        cleanDraft: false,
      );
    } else if (message.category.isTranscript) {
      final transcripts = await _transcriptMessageDao
          .transcriptMessageByTranscriptId(message.messageId)
          .get();
      await sendTranscriptMessage(
        conversationId: conversationId,
        senderId: senderId,
        transcripts: transcripts,
        encryptCategory: encryptCategory,
        cleanDraft: false,
      );
    }
  }

  Future<void> sendTranscriptMessage({
    required String conversationId,
    required String senderId,
    required List<TranscriptMessage> transcripts,
    EncryptCategory encryptCategory = EncryptCategory.plain,
    bool cleanDraft = true,
  }) async {
    final messageId = const Uuid().v4();

    final category = encryptCategory.toCategory(
      MessageCategory.plainTranscript,
      MessageCategory.signalTranscript,
      MessageCategory.encryptedTranscript,
    );

    final hasAttachments =
        transcripts.any((element) => element.category.isAttachment);

    final transcriptMessages = transcripts.map((e) {
      var mediaUrl = e.mediaUrl;
      var mediaStatus = e.mediaStatus;

      if (e.category.isAttachment) {
        mediaStatus = MediaStatus.canceled;
        if (e.mediaUrl == null) mediaUrl = null;
      }
      return e.copyWith(
        transcriptId: messageId,
        mediaUrl: Value(mediaUrl),
        mediaStatus: Value(mediaStatus),
      );
    }).toList();

    final transcriptMinimals = transcriptMessages
        .map((e) => TranscriptMinimal(
              name: e.userFullName ?? '',
              category: encryptCategory.asCategory(e.category),
              content: e.content,
            ).toJson())
        .toList();

    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      userId: senderId,
      category: category,
      content: await jsonEncodeWithIsolate(transcriptMinimals),
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
      mediaStatus: hasAttachments ? MediaStatus.canceled : MediaStatus.done,
    );

    await Future.wait([
      _transcriptMessageDao.insertAll(transcriptMessages),
      _insertSendMessageToDb(message,
          ftsContent: await _transcriptMessageDao
              .generateTranscriptMessageFts5Content(transcriptMessages),
          cleanDraft: cleanDraft),
    ]);

    if (hasAttachments) {
      await reUploadTranscriptAttachment(message.messageId);
    } else {
      _addSendingJob(await _jobDao.createSendingJob(
        message.messageId,
        conversationId,
      ));
    }
  }

  Future<void> reUploadTranscriptAttachment(String messageId) async {
    final message = await _messageDao.findMessageByMessageId(messageId);
    if (message == null) return;

    final status = message.mediaStatus;
    if (status == MediaStatus.done || status == MediaStatus.pending) return;
    final transcripts = await _transcriptMessageDao
        .transcriptMessageByTranscriptId(messageId)
        .get();

    if (!transcripts.any((element) => element.category.isAttachment)) {
      _addSendingJob(await _jobDao.createSendingJob(
        message.messageId,
        message.conversationId,
      ));
      return;
    }

    Future<void> uploadAttachment(TranscriptMessage transcriptMessage) async {
      if (transcriptMessage.mediaStatus == MediaStatus.done) return;
      final category = transcriptMessage.category;

      final isPlain = category.isPlain;
      final isValidAttachment = category.isAttachment &&
          ((isPlain &&
                  transcriptMessage.mediaKey == null &&
                  transcriptMessage.mediaDigest == null) ||
              (transcriptMessage.mediaKey != null &&
                  transcriptMessage.mediaDigest != null));
      final isBefore24Hours = transcriptMessage.mediaCreatedAt
              ?.isBefore(DateTime.now().subtract(const Duration(days: 1))) ??
          true;
      final encryptCategory = message.category.encryptCategory;

      var needUpload =
          encryptCategory != category.encryptCategory || isBefore24Hours;

      String? attachmentId;
      if (!needUpload) {
        Future<String?> getAttachmentId(String? content) async {
          try {
            final map = await jsonBase64DecodeWithIsolate(content ?? '');
            final attachmentMessage =
                AttachmentMessage.fromJson(map as Map<String, dynamic>);
            return attachmentMessage.attachmentId;
          } catch (_) {
            return content;
          }
        }

        if (isValidAttachment) {
          attachmentId = await getAttachmentId(transcriptMessage.content);
        } else {
          needUpload = true;
        }
      }

      if (needUpload || attachmentId == null) {
        final absolutePath = _attachmentUtil.convertAbsolutePath(
          fileName: transcriptMessage.mediaUrl,
          messageId: transcriptMessage.messageId,
          isTranscript: true,
        );
        final newCategory = encryptCategory?.asCategory(category) ?? category;
        final attachmentResult = await _attachmentUtil.uploadAttachment(
          File(absolutePath),
          transcriptMessage.messageId,
          newCategory,
          transcriptId: transcriptMessage.transcriptId,
        );
        attachmentId = attachmentResult!.attachmentId;

        await _transcriptMessageDao.updateTranscript(
          transcriptId: transcriptMessage.transcriptId,
          messageId: transcriptMessage.messageId,
          attachmentId: attachmentId,
          category: newCategory,
          key: attachmentResult.keys,
          digest: attachmentResult.digest,
          mediaStatus: MediaStatus.done,
          mediaCreatedAt: DateTime.tryParse(attachmentResult.createdAt ?? '') ??
              DateTime.now(),
        );
      } else {
        await _transcriptMessageDao.updateTranscript(
          transcriptId: transcriptMessage.transcriptId,
          messageId: transcriptMessage.messageId,
          attachmentId: attachmentId,
          category: transcriptMessage.category,
          key: transcriptMessage.mediaKey,
          digest: transcriptMessage.mediaDigest,
          mediaStatus: MediaStatus.done,
          mediaCreatedAt: transcriptMessage.mediaCreatedAt,
        );
      }
    }

    try {
      await _messageDao.updateMediaStatus(
        message.messageId,
        MediaStatus.pending,
      );
      final attachmentTranscripts =
          transcripts.where((element) => element.category.isAttachment);
      if (attachmentTranscripts.isNotEmpty) {
        await Future.wait(attachmentTranscripts.map(uploadAttachment));
      }

      await _messageDao.updateMediaStatus(
        message.messageId,
        MediaStatus.done,
      );
      _addSendingJob(await _jobDao.createSendingJob(
        message.messageId,
        message.conversationId,
      ));
    } catch (error, stacktrace) {
      e('reUploadTranscriptAttachment error: $error, stacktrace: $stacktrace');
      await _messageDao.updateMediaStatus(
        message.messageId,
        MediaStatus.canceled,
      );
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
      attachmentResult = await _checkAttachmentMessage(content);
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
      messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(messageId, conversationId));
  }

  Future<AttachmentResult?> _checkAttachmentExtra(Message message) async {
    AttachmentExtra? attachmentExtra;
    try {
      attachmentExtra = AttachmentExtra.fromJson(
          await jsonDecodeWithIsolate(message.content ?? '')
              as Map<String, dynamic>);
    } catch (e) {
      w('check attachment extra error: $e, content: ${message.content}');
      attachmentExtra = null;
    }
    if (attachmentExtra == null) {
      return null;
    }
    final createdAt = attachmentExtra.createdAt;
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt)?.toLocal();
      final difference = date?.difference(DateTime.now());
      if (difference != null &&
          difference.inMilliseconds <
              const Duration(hours: 24).inMilliseconds) {
        return AttachmentResult(
          attachmentExtra.attachmentId,
          message.mediaKey,
          message.mediaDigest,
          attachmentExtra.createdAt,
        );
      }
    }
    return null;
  }

  Future<AttachmentResult?> _checkAttachmentMessage(String content) async {
    AttachmentMessage? attachmentMessage;
    try {
      attachmentMessage = AttachmentMessage.fromJson(
          await jsonBase64DecodeWithIsolate(content) as Map<String, dynamic>);
    } catch (e) {
      attachmentMessage = null;
    }
    if (attachmentMessage == null) {
      return null;
    }
    final createdAt = attachmentMessage.createdAt;
    if (createdAt != null) {
      final date = DateTime.tryParse(createdAt);
      if (date?.isToady == true) {
        return AttachmentResult(
          attachmentMessage.attachmentId,
          attachmentMessage.key as String?,
          attachmentMessage.digest as String?,
          attachmentMessage.createdAt,
        );
      }
    }
    return null;
  }

  Future<void> sendPinMessage({
    required String conversationId,
    required String senderId,
    required List<PinMessageMinimal> pinMessageMinimals,
    required bool pin,
  }) async {
    if (pinMessageMinimals.isEmpty) return;

    final pinMessagePayload = PinMessagePayload(
      action: pin ? PinMessagePayloadAction.pin : PinMessagePayloadAction.unpin,
      messageIds: pinMessageMinimals.map((e) => e.messageId).toList(),
    );
    final encoded = await jsonEncodeWithIsolate(pinMessagePayload);
    if (pin) {
      await Future.forEach<PinMessageMinimal>(pinMessageMinimals,
          (pinMessageMinimal) async {
        await _pinMessageDao.insert(
          PinMessage(
            messageId: pinMessageMinimal.messageId,
            conversationId: conversationId,
            createdAt: DateTime.now(),
          ),
        );

        await _messageDao.insert(
          Message(
            messageId: const Uuid().v4(),
            conversationId: conversationId,
            userId: senderId,
            status: MessageStatus.read,
            content: await jsonEncodeWithIsolate(pinMessageMinimal),
            createdAt: DateTime.now(),
            category: MessageCategory.messagePin,
            quoteMessageId: pinMessageMinimal.messageId,
          ),
          senderId,
          cleanDraft: false,
        );
      });
      unawaited(ShowPinMessageKeyValue.instance.show(conversationId));
    } else {
      await _pinMessageDao
          .deleteByIds(pinMessageMinimals.map((e) => e.messageId).toList());
    }

    _addSendingJob(createSendPinJob(conversationId, encoded));
  }

  Future<void> sendImageMessageByUrl(
    String conversationId,
    String senderId,
    String category,
    String url,
    String previewUrl, {
    int? width,
    int? height,
    bool defaultGifMimeType = true,
  }) async {
    final messageId = const Uuid().v4();
    final defaultMimeType = defaultGifMimeType ? gifMimeType : jpegMimeType;

    Future<Message> insertMessage(
        int? width, int? height, String mimeType) async {
      final message = Message(
        messageId: messageId,
        conversationId: conversationId,
        userId: senderId,
        content: '',
        category: category,
        mediaUrl: url,
        mediaMimeType: mimeType,
        mediaSize: 0,
        mediaWidth: width,
        mediaHeight: height,
        mediaStatus: MediaStatus.pending,
        status: MessageStatus.sending,
        createdAt: DateTime.now(),
        thumbImage: previewUrl,
      );
      await _insertSendMessageToDb(message);
      return message;
    }

    if (width != null && height != null && defaultGifMimeType) {
      await insertMessage(width, height, defaultMimeType);
    }

    (Uint8List, ImageType, int, int)? result;
    try {
      final data = await downloadImage(url);
      if (data != null) {
        result = await compressWithIsolate(data);
      }
    } catch (error, stacktrace) {
      e('failed to download image: $error $stacktrace');
    }
    if (result == null) {
      e('failed to get send image bytes. $url');
      await _messageDao.updateMediaStatus(messageId, MediaStatus.canceled);
      return;
    }

    final (data, type, _width, _height) = result;

    await insertMessage(_width, _height, type.mimeType);

    var attachment = _attachmentUtil.getAttachmentFile(
      category,
      conversationId,
      messageId,
      null,
      mimeType: defaultMimeType,
    );
    attachment = await attachment.create(recursive: true);
    await attachment.writeAsBytes(data);
    final thumbImage = await attachment.encodeBlurHash();
    final mediaSize = await attachment.length();
    await _messageDao.updateGiphyMessage(
      messageId,
      attachment.pathBasename,
      mediaSize,
      thumbImage,
    );

    if (await _attachmentUtil.isNotPending(messageId)) return;

    final attachmentResult = await _attachmentUtil.uploadAttachment(
      attachment,
      messageId,
      category,
    );
    if (attachmentResult == null) return;

    final attachmentMessage = AttachmentMessage(
      attachmentResult.keys,
      attachmentResult.digest,
      attachmentResult.attachmentId,
      defaultMimeType,
      mediaSize,
      null,
      _width,
      _height,
      thumbImage,
      null,
      null,
      null,
      attachmentResult.createdAt,
    );
    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
      messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(messageId, conversationId));
  }

  Future<void> reUploadGiphyGif(MessageItem message) async {
    await _messageDao.updateMediaStatus(message.messageId, MediaStatus.pending);
    final attachment = _attachmentUtil.getAttachmentFile(
      message.type,
      message.conversationId,
      message.messageId,
      null,
      mimeType: message.mediaMimeType,
    );
    if (!attachment.existsSync()) {
      await attachment.create(recursive: true);
    }

    String? thumbImage;
    var mediaSize = await attachment.length();

    if (attachment.lengthSync() == 0) {
      Uint8List? sendImageBytes;
      try {
        sendImageBytes = await downloadImage(message.mediaUrl!);
      } catch (error, stacktrace) {
        e('reUploadGiphyGif: failed to download image: $error $stacktrace');
      }
      if (sendImageBytes == null) {
        e('reUploadGiphyGif: failed to get send image bytes. ${message.mediaUrl}');
        await _messageDao.updateMediaStatus(
            message.messageId, MediaStatus.canceled);
        return;
      }
      await attachment.writeAsBytes(sendImageBytes);

      thumbImage = await attachment.encodeBlurHash();
      mediaSize = await attachment.length();

      await _messageDao.updateGiphyMessage(
        message.messageId,
        attachment.pathBasename,
        mediaSize,
        thumbImage,
      );
    }
    final attachmentResult = await _attachmentUtil.uploadAttachment(
      attachment,
      message.messageId,
      message.type,
    );
    if (attachmentResult == null) return;

    final attachmentMessage = AttachmentMessage(
      attachmentResult.keys,
      attachmentResult.digest,
      attachmentResult.attachmentId,
      message.mediaMimeType!,
      mediaSize,
      null,
      message.mediaWidth,
      message.mediaHeight,
      thumbImage,
      null,
      null,
      null,
      attachmentResult.createdAt,
    );
    final encoded = await jsonBase64EncodeWithIsolate(attachmentMessage);
    await _messageDao.updateAttachmentMessageContentAndStatus(
      message.messageId,
      encoded,
      attachmentResult.keys,
      attachmentResult.digest,
    );
    _addSendingJob(await _jobDao.createSendingJob(
        message.messageId, message.conversationId));
  }
}
