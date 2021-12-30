import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

// ignore: implementation_imports
import 'package:mixin_bot_sdk_dart/src/vo/signal_key_count.dart';
import 'package:uuid/uuid.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../account/show_pin_message_key_value.dart';
import '../blaze/blaze_message.dart';
import '../blaze/vo/blaze_message_data.dart';
import '../blaze/vo/pin_message_minimal.dart';
import '../blaze/vo/pin_message_payload.dart';
import '../blaze/vo/plain_json_message.dart';
import '../blaze/vo/recall_message.dart';
import '../blaze/vo/snapshot_message.dart';
import '../blaze/vo/system_circle_message.dart';
import '../blaze/vo/system_conversation_message.dart';
import '../blaze/vo/system_user_message.dart';
import '../blaze/vo/transcript_minimal.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/signal/ratchet_status.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../crypto/uuid/uuid.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart';
import '../db/mixin_database.dart' as db;
import '../enum/media_status.dart';
import '../enum/message_action.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../enum/system_circle_action.dart';
import '../enum/system_user_action.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/extension/extension.dart';
import '../utils/logger.dart';
import 'injector.dart';
import 'sender.dart';

class DecryptMessage extends Injector {
  DecryptMessage(
    String userId,
    Database database,
    this._signalProtocol,
    this._sender,
    Client client,
    this._sessionId,
    this._privateKey,
    this._attachmentUtil,
    this.identityNumber,
  ) : super(userId, database, client) {
    _encryptedProtocol = EncryptedProtocol();
  }

  String? _conversationId;
  late final SignalProtocol _signalProtocol;
  late final Sender _sender;
  late final String _sessionId;
  late final PrivateKey _privateKey;
  late EncryptedProtocol _encryptedProtocol;

  final AttachmentUtil _attachmentUtil;

  final String identityNumber;

  final refreshKeyMap = <String, int?>{};

  bool photoAutoDownload = true;

  bool videoAutoDownload = true;

  bool fileAutoDownload = true;

  set conversationId(String? conversationId) {
    _conversationId = conversationId;
  }

  late MessageStatus _remoteStatus;

  Future<bool> isExistMessage(String messageId) async {
    final id = await database.messageDao.findMessageIdByMessageId(messageId);
    if (id != null) {
      return true;
    }
    final messageHistory =
        await database.messagesHistoryDao.findMessageHistoryById(messageId);
    return messageHistory != null;
  }

  Future<void> process(FloodMessage floodMessage) async {
    final data = BlazeMessageData.fromJson(
        jsonDecode(floodMessage.data) as Map<String, dynamic>);
    d('DecryptMessage process data: ${data.toJson()}');
    if (await isExistMessage(data.messageId)) {
      await _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
      await database.floodMessageDao.deleteFloodMessage(floodMessage);
      return;
    }
    try {
      _remoteStatus = MessageStatus.delivered;

      await syncConversion(data.conversationId);
      final category = data.category;
      if (category.isIllegalMessageCategory) {
        final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          content: data.data,
          createdAt: data.createdAt,
          status: data.status,
        );
        await database.messageDao.insert(message, accountId, data.silent);
      } else if (category.isSignal) {
        d('DecryptMessage isSignal');
        if (data.category == MessageCategory.signalKey) {
          _remoteStatus = MessageStatus.read;
          await database.messagesHistoryDao
              .insert(MessagesHistoryData(messageId: data.messageId));
        }
        await _processSignalMessage(data);
      } else if (category.isPlain) {
        d('DecryptMessage isPlain');
        await _processPlainMessage(data);
      } else if (category.isEncrypted) {
        d('DecryptMessage isEncrypted');
        await _processEncryptedMessage(data);
      } else if (category.isSystem) {
        d('DecryptMessage isSystem');
        _remoteStatus = MessageStatus.read;
        await _processSystemMessage(data);
      } else if (category == MessageCategory.appButtonGroup ||
          category == MessageCategory.appCard) {
        d('DecryptMessage isApp');
        await _processApp(data);
      } else if (category.isPin) {
        d('DecryptMessage isMessagePin');
        await _processPinMessage(data);
        _remoteStatus = MessageStatus.read;
      } else if (category == MessageCategory.messageRecall) {
        d('DecryptMessage isMessageRecall');
        _remoteStatus = MessageStatus.read;
        await _processRecallMessage(data);
      } else {
        _remoteStatus = MessageStatus.delivered;
      }
    } catch (e, s) {
      w('process error $e, stack $s');
      await _insertInvalidMessage(data);
      _remoteStatus = MessageStatus.delivered;
    }

    await _updateRemoteMessageStatus(
      floodMessage.messageId,
      _remoteStatus,
    );

    await database.floodMessageDao.deleteFloodMessage(floodMessage);
  }

  Future<void> _processSignalMessage(BlazeMessageData data) async {
    final deviceId = data.sessionId.getDeviceId();
    try {
      final composeMessageData = _signalProtocol.decodeMessageData(data.data);
      await _signalProtocol.decrypt(
          data.conversationId,
          data.senderId,
          composeMessageData.keyType,
          composeMessageData.cipher,
          data.category?.toString() ?? '',
          data.sessionId, (plaintext) async {
        if (data.category != MessageCategory.signalKey) {
          final plain = utf8.decode(plaintext);
          if (composeMessageData.resendMessageId != null) {
            await _processReDecryptMessage(
                data, composeMessageData.resendMessageId!, plain);
            await database.messagesHistoryDao
                .insert(MessagesHistoryData(messageId: data.messageId));
          } else {
            try {
              await _processDecryptSuccess(data, plain);
            } on Exception catch (e) {
              w('_processDecryptSuccess ${data.messageId}, $e');
              await _insertInvalidMessage(data);
            }
          }
        }

        final address = SignalProtocolAddress(data.senderId, deviceId);
        final status = (await SignalDatabase.get.ratchetSenderKeyDao
                .getRatchetSenderKey(data.conversationId, address.toString()))
            ?.status;
        if (status == RatchetStatus.requesting.name) {
          await _requestResendMessage(
              data.conversationId, data.senderId, data.sessionId);
        }
      });
    } on Exception catch (e) {
      i('decrypt failed ${data.messageId}, $e');
      await _refreshSignalKeys(data.conversationId);
      if (data.category == MessageCategory.signalKey) {
        await SignalDatabase.get.ratchetSenderKeyDao.deleteByGroupIdAndSenderId(
            data.conversationId,
            SignalProtocolAddress(data.senderId, deviceId).toString());
      } else {
        await _insertFailedMessage(data);
        final address = SignalProtocolAddress(data.senderId, deviceId);
        final status = (await SignalDatabase.get.ratchetSenderKeyDao
                .getRatchetSenderKey(data.conversationId, address.toString()))
            ?.status;
        if (status == null) {
          await _requestResendKey(data.conversationId, data.senderId,
              data.messageId, data.sessionId);
        }
      }
    }
  }

  Future<void> _processPlainMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.plainJson) {
      final plainJsonMessage = PlainJsonMessage.fromJson(
          _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);
      if (plainJsonMessage.action == kAcknowledgeMessageReceipts) {
        if (plainJsonMessage.ackMessages?.isNotEmpty != true) {
          return;
        }
        await _markMessageStatus(plainJsonMessage.ackMessages!);
      } else if (plainJsonMessage.action == kResendMessages) {
        await _processResendMessage(data, plainJsonMessage);
      } else if (plainJsonMessage.action == kResendKey) {
        if (await _signalProtocol.containsUserSession(data.userId)) {
          unawaited(_sender.sendProcessSignalKey(
              data, ProcessSignalKeyAction.resendKey));
        }
      }
      await database.messagesHistoryDao
          .insert(MessagesHistoryData(messageId: data.messageId));
    } else if (data.category == MessageCategory.plainText ||
        data.category == MessageCategory.plainImage ||
        data.category == MessageCategory.plainVideo ||
        data.category == MessageCategory.plainData ||
        data.category == MessageCategory.plainAudio ||
        data.category == MessageCategory.plainContact ||
        data.category == MessageCategory.plainSticker ||
        data.category == MessageCategory.plainLive ||
        data.category == MessageCategory.plainPost ||
        data.category == MessageCategory.plainLocation ||
        data.category == MessageCategory.plainTranscript) {
      await _processDecryptSuccess(data, data.data);
    }
  }

  Future<void> _processEncryptedMessage(BlazeMessageData data) async {
    try {
      final decryptedContent = _encryptedProtocol.decryptMessage(
          _privateKey, Uuid.parse(_sessionId), base64Decode(data.data));
      if (decryptedContent == null) {
        await _insertInvalidMessage(data);
      } else {
        final plainText = utf8.decode(decryptedContent);
        try {
          await _processDecryptSuccess(data, plainText);
        } catch (e) {
          w('insertInvalidMessage ${data.messageId}, $e');
          await _insertInvalidMessage(data);
        }
      }
    } catch (e) {
      await _insertInvalidMessage(data);
    }
  }

  Future<void> _processResendMessage(
      BlazeMessageData data, PlainJsonMessage plainData) async {
    final messages = plainData.messages;
    if (messages == null) {
      return;
    }
    final p = await database.participantDao
        .participantById(data.conversationId, data.userId)
        .getSingleOrNull();
    if (p == null) {
      return;
    }
    for (final id in messages) {
      final resendMessage = await database.resendSessionMessageDao
          .findResendMessage(data.userId, data.sessionId, id);
      if (resendMessage != null) {
        continue;
      }
      final needResendMessage = await database.messageDao
          .findMessageByMessageIdAndUserId(id, accountId);
      if (needResendMessage == null ||
          needResendMessage.category == MessageCategory.messageRecall) {
        await database.resendSessionMessageDao.insert(ResendSessionMessage(
            messageId: id,
            userId: data.userId,
            sessionId: data.sessionId,
            status: 0,
            createdAt: DateTime.now()));
        continue;
      }
      if (!needResendMessage.category.isSignal) {
        continue;
      }
      if (p.createdAt.isAfter(needResendMessage.createdAt)) {
        continue;
      }
      await database.resendSessionMessageDao.insert(ResendSessionMessage(
          messageId: id,
          userId: data.userId,
          sessionId: data.sessionId,
          status: 1,
          createdAt: DateTime.now()));
      await database.jobDao.insertSendingJob(id, data.conversationId);
    }
  }

  Future<void> _processSystemMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.systemConversation) {
      final systemMessage = SystemConversationMessage.fromJson(
          _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);
      await _processSystemConversationMessage(data, systemMessage);
    } else if (data.category == MessageCategory.systemUser) {
      final systemMessage = SystemUserMessage.fromJson(
          _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);
      await _processSystemUserMessage(systemMessage);
    } else if (data.category == MessageCategory.systemCircle) {
      final systemMessage = SystemCircleMessage.fromJson(
          _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);
      await _processSystemCircleMessage(data, systemMessage);
    } else if (data.category == MessageCategory.systemAccountSnapshot) {
      final systemSnapshot = SnapshotMessage.fromJson(
          _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);
      await _processSystemSnapshotMessage(data, systemSnapshot);
    }
  }

  Future<void> _processApp(BlazeMessageData data) async {
    d('data.conversationId: ${data.conversationId}, _conversationId: $_conversationId');
    if (data.category == MessageCategory.appButtonGroup) {
      await _processAppButton(data);
    } else if (data.category == MessageCategory.appCard) {
      await _processAppCard(data);
    }
  }

  Future<void> _processAppButton(BlazeMessageData data) async {
    final content = _decodeWithIsolate(data.data);
    // final apps = (await _decodeWithIsolate(data.data) as List)
    //     .map((e) =>
    //         e == null ? null : AppButton.fromJson(e as Map<String, dynamic>))
    //     .toList();
    // todo check
    final message = Message(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.senderId,
      category: data.category!,
      content: content,
      status: data.status,
      createdAt: data.createdAt,
    );
    await database.messageDao.insert(message, accountId, data.silent);
  }

  Future<void> _processAppCard(BlazeMessageData data) async {
    await refreshUsers(<String>[data.userId]);
    final content = _decodeWithIsolate(data.data);
    final appCard =
        AppCard.fromJson(jsonDecode(content) as Map<String, dynamic>);
    final message = Message(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.senderId,
      category: data.category!,
      content: content,
      status: data.status,
      createdAt: data.createdAt,
    );
    await database.appDao.findAppById(appCard.appId).then((app) {
      if (app == null || app.updatedAt != appCard.updatedAt) {
        refreshUsers(<String>[appCard.appId]);
      }
    });
    await database.messageDao.insert(message, accountId, data.silent);
  }

  Future<void> _processPinMessage(BlazeMessageData data) async {
    final pinMessage = PinMessagePayload.fromJson(
        _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);

    if (pinMessage.action == PinMessagePayloadAction.pin) {
      await Future.forEach<String>(pinMessage.messageIds, (messageId) async {
        final message =
            await database.messageDao.findMessageByMessageId(messageId);
        if (message == null) return;
        final pinMessageMinimal = PinMessageMinimal(
          type: message.category,
          messageId: message.messageId,
          content: message.category.isText ? message.content : null,
        );
        await database.pinMessageDao.insert(PinMessage(
          messageId: messageId,
          conversationId: message.conversationId,
          createdAt: data.createdAt,
        ));
        await database.messageDao.insert(
          Message(
            messageId: const Uuid().v4(),
            conversationId: data.conversationId,
            quoteMessageId: message.messageId,
            userId: data.userId,
            status: MessageStatus.read,
            content: jsonEncode(pinMessageMinimal),
            createdAt: data.createdAt,
            category: MessageCategory.messagePin,
          ),
          accountId,
        );
      });
      // FIXME background isolate can not access this.
      unawaited(ShowPinMessageKeyValue.instance.show(data.conversationId));
    } else if (pinMessage.action == PinMessagePayloadAction.unpin) {
      await database.pinMessageDao.deleteByIds(pinMessage.messageIds);
    }
    await database.messagesHistoryDao
        .insert(MessagesHistoryData(messageId: data.messageId));
  }

  Future<void> _processRecallMessage(BlazeMessageData data) async {
    final recallMessage = RecallMessage.fromJson(
        _jsonDecodeWithIsolate(data.data) as Map<String, dynamic>);
    final message = await database.messageDao
        .findMessageByMessageId(recallMessage.messageId);
    if (message?.category.isAttachment == true) {
      await _attachmentUtil
          .cancelProgressAttachmentJob(recallMessage.messageId);
      if (message?.mediaUrl?.isNotEmpty ?? false) {
        final file = File(message!.mediaUrl!);
        final exists = file.existsSync();
        if (exists) {
          await file.delete();
        }
      }
    }
    await database.messageDao.recallMessage(recallMessage.messageId);
    await database.messageMentionDao
        .deleteMessageMentionByMessageId(recallMessage.messageId);
    final quoteMessage = await database.messageDao
        .findMessageItemById(data.conversationId, recallMessage.messageId);
    if (quoteMessage != null) {
      await database.messageDao.updateQuoteContentByQuoteId(
          data.conversationId, recallMessage.messageId, quoteMessage.toJson());
    }
    await database.messageDao.deleteFtsByMessageId(recallMessage.messageId);
    await database.messagesHistoryDao
        .insert(MessagesHistoryData(messageId: data.messageId));
  }

  Future<Message> _generateMessage(
      BlazeMessageData data, MessageGenerator generator) async {
    if (data.quoteMessageId == null || (data.quoteMessageId?.isEmpty ?? true)) {
      return generator(null);
    }

    final quoteMessage = await database.messageDao
        .findMessageItemById(data.conversationId, data.quoteMessageId!);

    if (quoteMessage != null) {
      return generator(quoteMessage);
    } else {
      return generator(null);
    }
  }

  Future<void> _processDecryptSuccess(
    BlazeMessageData data,
    String plainText,
  ) async {
    await refreshUsers(<String>[data.senderId]);

    if (data.category.isText) {
      String plain;
      if (data.category == MessageCategory.signalText ||
          data.category == MessageCategory.encryptedText) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      QuoteMessageItem? _quoteContent;
      final message =
          await _generateMessage(data, (QuoteMessageItem? quoteContent) {
        _quoteContent = quoteContent;
        return Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          content: plain,
          status: data.status,
          createdAt: data.createdAt,
          quoteMessageId: data.quoteMessageId,
          quoteContent: quoteContent?.toJson(),
        );
      });
      await database.messageMentionDao.parseMentionData(
        message.content,
        message.messageId,
        message.conversationId,
        data.senderId,
        _quoteContent,
        accountId,
        identityNumber,
      );
      await database.messageDao.insert(message, accountId, data.silent);
    } else if (data.category.isImage) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              mediaMimeType: attachment.mimeType,
              mediaSize: attachment.size,
              mediaWidth: attachment.width,
              mediaHeight: attachment.height,
              thumbImage: attachment.thumbnail,
              mediaKey: attachment.key as String?,
              mediaDigest: attachment.digest as String?,
              status: data.status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.canceled,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent?.toJson()));
      await database.messageDao.insert(message, accountId, data.silent);
      if (photoAutoDownload) {
        unawaited(
          _attachmentUtil.downloadAttachment(messageId: message.messageId),
        );
      }
    } else if (data.category.isVideo) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              name: attachment.name,
              mediaMimeType: attachment.mimeType,
              mediaDuration: attachment.duration.toString(),
              mediaSize: attachment.size,
              mediaWidth: attachment.width,
              mediaHeight: attachment.height,
              thumbImage: attachment.thumbnail,
              mediaKey: attachment.key as String?,
              mediaDigest: attachment.digest as String?,
              status: data.status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.canceled,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent?.toJson()));
      await database.messageDao.insert(message, accountId, data.silent);
      if (videoAutoDownload) {
        unawaited(
          _attachmentUtil.downloadAttachment(messageId: message.messageId),
        );
      }
    } else if (data.category.isData) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              name: attachment.name,
              mediaMimeType: attachment.mimeType,
              mediaSize: attachment.size,
              mediaKey: attachment.key as String?,
              mediaDigest: attachment.digest as String?,
              status: data.status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.canceled,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent?.toJson()));
      await database.messageDao.insert(message, accountId, data.silent);
      if (fileAutoDownload) {
        unawaited(
          _attachmentUtil.downloadAttachment(messageId: message.messageId),
        );
      }
    } else if (data.category.isAudio) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              name: attachment.name,
              mediaMimeType: attachment.mimeType,
              mediaSize: attachment.size,
              mediaDuration: '${attachment.duration ?? 0}',
              mediaKey: attachment.key as String?,
              mediaDigest: attachment.digest as String?,
              mediaWaveform: attachment.waveform as String?,
              status: data.status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.pending,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent?.toJson()));
      await database.messageDao.insert(message, accountId, data.silent);
      unawaited(
        _attachmentUtil.downloadAttachment(messageId: message.messageId),
      );
    } else if (data.category.isSticker) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final stickerMessage = StickerMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final sticker = await database.stickerDao
          .getStickerByUnique(stickerMessage.stickerId)
          .getSingleOrNull();
      if (sticker == null) {
        await refreshSticker(stickerMessage.stickerId);
      }
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          content: plainText,
          name: stickerMessage.name,
          stickerId: stickerMessage.stickerId,
          albumId: stickerMessage.albumId,
          status: data.status,
          createdAt: data.createdAt);
      await database.messageDao.insert(message, accountId, data.silent);
    } else if (data.category.isContact) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final contactMessage = ContactMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final user = (await refreshUsers(<String>[contactMessage.userId]))?.first;
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: plainText,
              name: user?.fullName,
              sharedUserId: contactMessage.userId,
              status: data.status,
              createdAt: data.createdAt,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent?.toJson()));
      await database.messageDao.insert(message, accountId, data.silent);
    } else if (data.category.isLive) {
      final String plain;
      if (data.category.isEncrypted) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final liveMessage =
          LiveMessage.fromJson(await jsonDecode(plain) as Map<String, dynamic>);
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          mediaWidth: liveMessage.width,
          mediaHeight: liveMessage.height,
          mediaUrl: liveMessage.url,
          thumbUrl: liveMessage.thumbUrl,
          status: data.status,
          createdAt: data.createdAt);
      await database.messageDao.insert(message, accountId, data.silent);
    } else if (data.category.isLocation) {
      String plain;
      if (data.category == MessageCategory.signalLocation ||
          data.category == MessageCategory.encryptedLocation) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      // ignore: unused_local_variable todo check location
      LocationMessage? locationMessage;
      try {
        locationMessage = LocationMessage.fromJson(
          jsonDecode(plain) as Map<String, dynamic>,
        );
      } catch (e, s) {
        w('decode locationMessage error $e, $s');
      }
      if (locationMessage == null ||
          locationMessage.latitude == 0.0 ||
          locationMessage.longitude == 0.0) {
        _remoteStatus = MessageStatus.read;
        return;
      }
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          content: plain,
          status: data.status,
          createdAt: data.createdAt);
      await database.messageDao.insert(message, accountId, data.silent);
    } else if (data.category.isPost) {
      String plain;
      if (data.category == MessageCategory.signalPost ||
          data.category == MessageCategory.encryptedPost) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.senderId,
        category: data.category!,
        content: plain,
        status: data.status,
        createdAt: data.createdAt,
      );
      await database.messageDao.insert(message, accountId, data.silent);
    } else if (data.category.isTranscript) {
      String plain;
      if (data.category == MessageCategory.signalTranscript ||
          data.category == MessageCategory.encryptedTranscript) {
        plain = plainText;
      } else {
        plain = _decodeWithIsolate(plainText);
      }
      final list = jsonDecode(plain) as List<dynamic>;
      final message = await processTranscriptMessage(data, list);
      if (message != null) {
        await database.messageDao.insert(message, accountId, data.silent);
      }
    }
  }

  Future<void> _processSystemConversationMessage(
      BlazeMessageData data, SystemConversationMessage systemMessage) async {
    if (systemMessage.action != MessageAction.update) {
      await syncConversion(data.conversationId);
    }
    final userId = systemMessage.userId ?? data.senderId;
    if (userId == systemUser &&
        (await database.userDao.userById(userId).getSingleOrNull()) == null) {
      await database.userDao.insert(db.User(
        userId: systemUser,
        identityNumber: '0',
      ));
    }
    final message = db.Message(
        messageId: data.messageId,
        userId: userId,
        conversationId: data.conversationId,
        category: data.category!,
        content: '',
        createdAt: data.createdAt,
        status: data.status,
        action: systemMessage.action,
        participantId: systemMessage.participantId);
    if (systemMessage.action == MessageAction.add ||
        systemMessage.action == MessageAction.join) {
      await database.participantDao.insert(db.Participant(
          conversationId: data.conversationId,
          userId: systemMessage.participantId!,
          createdAt: data.createdAt));
      if (systemMessage.participantId == accountId) {
        await syncConversion(data.conversationId, force: true, unWait: true);
      } else if (systemMessage.participantId != accountId &&
          await _signalProtocol.isExistSenderKey(
              data.conversationId, accountId)) {
        unawaited(_sender.sendProcessSignalKey(
            data, ProcessSignalKeyAction.addParticipant,
            participantId: systemMessage.participantId));
        await refreshUsers(<String>[systemMessage.participantId!]);
      } else {
        final userIds = <String>[systemMessage.participantId!];
        unawaited(_sender.refreshSession(data.conversationId, userIds));
        await refreshUsers(<String>[systemMessage.participantId!]);
      }
    } else if (systemMessage.action == MessageAction.remove ||
        systemMessage.action == MessageAction.exit) {
      if (systemMessage.participantId == accountId) {
        unawaited(database.conversationDao.updateConversationStatusById(
            data.conversationId, ConversationStatus.quit));
      }
      await refreshUsers(<String>[systemMessage.participantId!]);
      unawaited(_sender.sendProcessSignalKey(
          data, ProcessSignalKeyAction.removeParticipant,
          participantId: systemMessage.participantId));
    } else if (systemMessage.action == MessageAction.update) {
      final participantId = systemMessage.participantId;
      if (participantId != null && participantId.isNotEmpty) {
        unawaited(
            refreshUsers(<String>[systemMessage.participantId!], force: true));
      } else {
        await syncConversion(data.conversationId, force: true, unWait: true);
      }
      return;
    } else if (systemMessage.action == MessageAction.create) {
    } else if (systemMessage.action == MessageAction.role) {
      await database.participantDao.updateParticipantRole(
        data.conversationId,
        systemMessage.participantId!,
        systemMessage.role,
      );
      if (systemMessage.participantId != accountId ||
          systemMessage.role == null) {
        return;
      }
    }
    await database.messageDao.insert(message, accountId, data.silent);
  }

  Future<void> _processSystemUserMessage(
      SystemUserMessage systemMessage) async {
    if (systemMessage.action == SystemUserAction.update) {
      unawaited(refreshUsers(<String>[systemMessage.userId], force: true));
    }
  }

  Future<void> _processSystemCircleMessage(
      BlazeMessageData data, SystemCircleMessage systemMessage) async {
    if (systemMessage.action == SystemCircleAction.create ||
        systemMessage.action == SystemCircleAction.update) {
      unawaited(refreshCircle(circleId: systemMessage.circleId));
    } else if (systemMessage.action == SystemCircleAction.add) {
      final circle =
          await database.circleDao.findCircleById(systemMessage.circleId);
      if (circle == null) {
        unawaited(refreshCircle(circleId: systemMessage.circleId));
      }
      final conversationId = systemMessage.conversationId;
      if (systemMessage.userId != null) {
        await refreshUsers(<String>[systemMessage.userId!]);
      }
      await database.circleConversationDao.insert(db.CircleConversation(
        conversationId: conversationId ??
            generateConversationId(accountId, systemMessage.userId!),
        circleId: systemMessage.circleId,
        userId: systemMessage.userId,
        createdAt: data.createdAt,
      ));
    } else if (systemMessage.action == SystemCircleAction.remove) {
      final conversationId = systemMessage.conversationId ??
          generateConversationId(accountId, systemMessage.userId!);
      await database.circleConversationDao
          .deleteByIds(conversationId, systemMessage.circleId);
    } else if (systemMessage.action == SystemCircleAction.delete) {
      await database.circleDao.deleteCircleById(systemMessage.circleId);
      await database.circleConversationDao
          .deleteByCircleId(systemMessage.circleId);
    }
  }

  Future<void> _processSystemSnapshotMessage(
      BlazeMessageData data, SnapshotMessage snapshotMessage) async {
    final snapshot = db.Snapshot(
      snapshotId: snapshotMessage.snapshotId,
      type: snapshotMessage.type,
      assetId: snapshotMessage.assetId,
      opponentId: snapshotMessage.opponentId,
      amount: snapshotMessage.amount,
      createdAt: DateTime.parse(
        snapshotMessage.createdAt,
      ),
    );
    await database.snapshotDao.insert(snapshot);
    await database.jobDao.insertUpdateAssetJob(Job(
      jobId: const Uuid().v4(),
      action: kUpdateAsset,
      priority: 5,
      runCount: 0,
      createdAt: DateTime.now(),
      blazeMessage: snapshotMessage.assetId,
    ));
    var status = data.status;
    if (_conversationId == data.conversationId && data.userId != accountId) {
      status = MessageStatus.read;
    }
    final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.senderId,
        category: data.category!,
        content: '',
        snapshotId: snapshot.snapshotId,
        status: status,
        createdAt: data.createdAt);
    await database.messageDao.insert(message, accountId, data.silent);
  }

  Future<void> _updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    await database.jobDao.insertNoReplace(
        createAckJob(kAcknowledgeMessageReceipts, messageId, status));
  }

  Future<void> _markMessageStatus(List<BlazeAckMessage> messages) async {
    final messageIds = <String>[];
    messages
        .where((m) => m.status == 'READ' || m.status == 'MENTION_READ')
        .forEach((m) async {
      if (m.status == 'MENTION_READ') {
        await database.messageMentionDao.markMentionRead(m.messageId);
      } else if (m.status == 'READ') {
        messageIds.add(m.messageId);
      }
    });

    if (messageIds.isNotEmpty) {
      await database.messageDao.markMessageRead(accountId, messageIds);
      final conversationIds =
          await database.messageDao.findConversationIdsByMessages(messageIds);
      for (final cId in conversationIds) {
        await database.messageDao.takeUnseen(accountId, cId);
      }
    }
  }

  Future<void> _insertInvalidMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.signalKey) {
      return;
    }
    final message = Message(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.senderId,
      content: data.data,
      category: data.category!,
      status: MessageStatus.unknown,
      createdAt: data.createdAt,
    );
    await database.messageDao.insert(message, accountId, data.silent);
  }

  Future<void> _insertFailedMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.signalText ||
        data.category == MessageCategory.signalImage ||
        data.category == MessageCategory.signalVideo ||
        data.category == MessageCategory.signalData ||
        data.category == MessageCategory.signalAudio ||
        data.category == MessageCategory.signalSticker ||
        data.category == MessageCategory.signalContact ||
        data.category == MessageCategory.signalLocation ||
        data.category == MessageCategory.signalPost) {
      final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.senderId,
        category: data.category!,
        content: data.data,
        status: MessageStatus.failed,
        createdAt: data.createdAt,
      );
      await database.messageDao.insert(message, accountId, data.silent);
    }
  }

  Future<void> _processReDecryptMessage(
      BlazeMessageData data, String messageId, String plaintext) async {
    if (data.category == MessageCategory.signalText) {
      await database.messageMentionDao.parseMentionData(
        plaintext,
        messageId,
        data.conversationId,
        data.senderId,
        null,
        accountId,
        identityNumber,
      );
      await database.messageDao
          .updateMessageContentAndStatus(messageId, plaintext, data.status);
    } else if (data.category == MessageCategory.signalPost) {
      await database.messageDao
          .updateMessageContentAndStatus(messageId, plaintext, data.status);
    } else if (data.category == MessageCategory.signalLocation) {
      await database.messageDao
          .updateMessageContentAndStatus(messageId, plaintext, data.status);
    } else if (data.category == MessageCategory.signalImage ||
        data.category == MessageCategory.signalVideo ||
        data.category == MessageCategory.signalData ||
        data.category == MessageCategory.signalAudio) {
      final attachment = AttachmentMessage.fromJson(
          _jsonDecodeWithIsolate(plaintext) as Map<String, dynamic>);
      final messagesCompanion = MessagesCompanion(
          status: Value(data.status),
          content: Value(attachment.attachmentId),
          mediaMimeType: Value(attachment.mimeType),
          mediaSize: Value(attachment.size),
          mediaStatus: const Value(MediaStatus.canceled),
          mediaWidth: Value(attachment.width),
          mediaHeight: Value(attachment.height),
          mediaDigest: Value(attachment.digest as String?),
          mediaKey: Value(attachment.key as String?),
          mediaWaveform: Value(attachment.waveform as String?),
          name: Value(attachment.name),
          thumbImage: Value(attachment.thumbnail),
          mediaDuration: Value(attachment.duration.toString()));
      await database.messageDao
          .updateAttachmentMessage(messageId, messagesCompanion);
    } else if (data.category == MessageCategory.signalSticker) {
      final plain = _decodeWithIsolate(plaintext);
      final stickerMessage = StickerMessage.fromJson(
        jsonDecode(plain) as Map<String, dynamic>,
      );
      final sticker = await database.stickerDao
          .getStickerByUnique(stickerMessage.stickerId)
          .getSingleOrNull();
      if (sticker == null) {
        await refreshSticker(stickerMessage.stickerId);
      }
      await database.messageDao.updateStickerMessage(
          messageId, data.status, stickerMessage.stickerId);
    } else if (data.category == MessageCategory.signalContact) {
      final plain = _decodeWithIsolate(plaintext);
      final contactMessage = ContactMessage.fromJson(
        jsonDecode(plain) as Map<String, dynamic>,
      );
      await database.messageDao
          .updateContactMessage(messageId, data.status, contactMessage.userId);
    } else if (data.category == MessageCategory.signalLive) {
      final plain = _decodeWithIsolate(plaintext);
      final liveMessage = LiveMessage.fromJson(
        jsonDecode(plain) as Map<String, dynamic>,
      );
      await database.messageDao.updateLiveMessage(
          messageId,
          liveMessage.width,
          liveMessage.height,
          liveMessage.url,
          liveMessage.thumbUrl,
          data.status);
    } else if (data.category == MessageCategory.signalTranscript) {
      final plain = _decodeWithIsolate(plaintext);
      final list = jsonDecode(plain) as List<dynamic>;
      final message = await processTranscriptMessage(data, list);
      if (message != null) {
        await database.messageDao.updateTranscriptMessage(message.content,
            message.mediaSize, message.mediaStatus, message.status, messageId);
      }
    }
    if (await database.messageDao
            .countMessageByQuoteId(data.conversationId, messageId) >
        0) {
      final messageItem = await database.messageDao
          .findMessageItemById(data.conversationId, messageId);
      if (messageItem != null) {
        await database.messageDao.updateQuoteContentByQuoteId(
            data.conversationId, messageId, messageItem.toJson());
      }
    }
  }

  Future<void> _requestResendKey(String conversationId, String recipientId,
      String messageId, String? sessionId) async {
    final plainJsonMessage =
        PlainJsonMessage(kResendKey, null, null, messageId, null, null);
    final encoded = _jsonEncodeWithIsolate(plainJsonMessage);
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, recipientId, encoded,
        sessionId: sessionId));
    final result = await _sender.deliver(bm);
    if (result.success) {
      final address =
          SignalProtocolAddress(recipientId, sessionId.getDeviceId());
      final ratchet = RatchetSenderKeysCompanion.insert(
          groupId: conversationId,
          senderId: address.toString(),
          status: RatchetStatus.requesting.name,
          createdAt: DateTime.now().millisecondsSinceEpoch.toString());
      await SignalDatabase.get.ratchetSenderKeyDao.insertSenderKey(ratchet);
    }
  }

  Future<void> _requestResendMessage(
      String conversationId, String userId, String? sessionId) async {
    final messages =
        await database.messageDao.findFailedMessages(conversationId, userId);
    if (messages.isEmpty) {
      return;
    }
    final plainJsonMessage = PlainJsonMessage(
        kResendMessages, messages.reversed.toList(), null, null, null, null);
    final encoded = _jsonEncodeWithIsolate(plainJsonMessage);
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, userId, encoded,
        sessionId: sessionId));
    unawaited(_sender.deliver(bm));
    await SignalDatabase.get.ratchetSenderKeyDao.deleteByGroupIdAndSenderId(
        conversationId,
        SignalProtocolAddress(userId, sessionId.getDeviceId()).toString());
  }

  Future<void> _refreshSignalKeys(String conversationId) async {
    final start = refreshKeyMap[conversationId] ?? 0;
    final current = DateTime.now().millisecondsSinceEpoch;
    if (start == 0) {
      refreshKeyMap[conversationId] = current;
    }
    if (current - start < 1000 * 60) {
      return;
    }
    refreshKeyMap[conversationId] = current;
    final blazeMessage = createCountSignalKeys();
    final data = (await _sender.signalKeysChannel(blazeMessage))?.data;
    final count = SignalKeyCount.fromJson(data as Map<String, dynamic>);
    if (count.preKeyCount >= preKeyMinNum) {
      return;
    }
    final bm =
        createSyncSignalKeys(createSyncSignalKeysParam(await generateKeys()));
    final result = await _sender.signalKeysChannel(bm);
    if (result == null) {
      i('Registering new pre keys...');
    }
  }

  void syncSession() {}

  Future<Message?>? processTranscriptMessage(
      BlazeMessageData data, List<dynamic> list) async {
    final transcripts = list
        .map((e) {
          // ignore: avoid_dynamic_calls
          e['created_at'] = DateTime.tryParse(e['created_at'] as String? ?? '')
              ?.millisecondsSinceEpoch;
          // ignore: avoid_dynamic_calls
          e['media_created_at'] =
              // ignore: avoid_dynamic_calls
              DateTime.tryParse(e['media_created_at'] as String? ?? '')
                  ?.millisecondsSinceEpoch;
          // ignore: avoid_dynamic_calls
          final mediaDuration = e['media_duration'];
          // ignore: avoid_dynamic_calls
          e['media_duration'] = mediaDuration != null ? '$mediaDuration' : null;
          return TranscriptMessage.fromJson(e as Map<String, dynamic>);
        })
        .where((transcript) => transcript.transcriptId == data.messageId)
        .whereNotNull()
        .toList();

    if (transcripts.isEmpty) {
      await _insertInvalidMessage(data);
      return null;
    }

    Future<void> insertFts() async {
      final contents = await Future.wait(transcripts.where((transcript) {
        final category = transcript.category;
        return category.isText ||
            category.isPost ||
            category.isData ||
            category.isContact;
      }).map((transcript) async {
        final category = transcript.category;
        if (category.isData) {
          return transcript.mediaName;
        }

        if (category.isContact &&
            (transcript.sharedUserId?.isNotEmpty ?? false)) {
          return database.userDao
              .userFullNameByUserId(transcript.sharedUserId!)
              .getSingleOrNull();
        }

        return transcript.content;
      }));

      final join = contents.whereNotNull().join(' ');
      await database.messageDao.insertFts(data.messageId, data.conversationId,
          join, data.createdAt, data.userId);
    }

    Future _refreshSticker() => Future.wait(transcripts
            .where((transcript) =>
                transcript.category.isSticker &&
                (transcript.stickerId?.isNotEmpty ?? false))
            .map((transcript) async {
          final hasSticker =
              await database.stickerDao.hasSticker(transcript.stickerId!);
          if (hasSticker) return;
          await refreshSticker(transcript.stickerId!);
        }));

    Future _refreshUser() => refreshUsers([
          ...transcripts.map((e) => e.userId).whereNotNull(),
          ...transcripts
              .where((transcript) =>
                  transcript.category.isContact &&
                  (transcript.sharedUserId?.isNotEmpty ?? false))
              .map((transcript) => transcript.sharedUserId!),
        ]);

    final attachmentTranscript =
        transcripts.where((transcript) => transcript.category.isAttachment);

    final insertAllTranscriptMessageFuture = database.transcriptMessageDao
        .insertAll(transcripts
            .map((transcript) => transcript.copyWith(
                mediaStatus: const Value(MediaStatus.canceled)))
            .toList());

    await Future.wait([
      insertFts(),
      _refreshSticker(),
      _refreshUser(),
      insertAllTranscriptMessageFuture,
    ]);

    final transcriptMinimalList =
        (transcripts..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
            .map((transcript) => TranscriptMinimal(
                  name: transcript.userFullName ?? '',
                  category: transcript.category,
                  content: transcript.content,
                ))
            .toList();

    final totalMediaSize = attachmentTranscript
        .where((transcript) => transcript.mediaSize != null)
        .map((transcript) => transcript.mediaSize!)
        .fold<int>(0, (a, b) => a + b);

    Future<bool> downloadTranscriptAttachment() async {
      var needDownload = false;

      final futures = transcripts
          .where((transcript) =>
              transcript.category.isAttachment && transcript.content != null)
          .map((transcript) async {
        final category = transcript.category;

        if (await _attachmentUtil.syncMessageMedia(transcript.messageId)) {
          return;
        }

        needDownload = needDownload || true;

        if (category.isImage && !photoAutoDownload) return;
        if (category.isVideo && !videoAutoDownload) return;
        if (category.isData && !fileAutoDownload) return;

        await _attachmentUtil.downloadAttachment(
          messageId: transcript.messageId,
        );
      });

      await Future.wait(futures);
      return needDownload;
    }

    final needDownload = await downloadTranscriptAttachment();

    final mediaStatus = (totalMediaSize == 0 || !needDownload)
        ? MediaStatus.done
        : MediaStatus.canceled;

    return Message(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.senderId,
      category: data.category!,
      content: jsonEncode(transcriptMinimalList),
      mediaSize: totalMediaSize,
      status: data.status,
      createdAt: data.createdAt,
      mediaStatus: mediaStatus,
    );
  }
}

dynamic _jsonDecode(String encoded) => jsonDecode(_decode(encoded));

String _decode(String encoded) => utf8.decode(base64Decode(encoded));

String _jsonEncode(Object object) =>
    base64Encode(utf8.encode(jsonEncode(object)));

dynamic _jsonDecodeWithIsolate(String encoded) => _jsonDecode(encoded);

String _jsonEncodeWithIsolate(Object object) => _jsonEncode(object);

String _decodeWithIsolate(String encoded) => _decode(encoded);

typedef MessageGenerator = Message Function(QuoteMessageItem? quoteMessageItem);
