import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze_message.dart';
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
import '../crypto/crypto_key_value.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/signal/ratchet_status.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../crypto/uuid/uuid.dart';
import '../db/dao/message_dao.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart' as db;
import '../db/mixin_database.dart';
import '../enum/media_status.dart';
import '../enum/message_action.dart';
import '../enum/message_category.dart';
import '../enum/system_circle_action.dart';
import '../enum/system_user_action.dart';
import '../utils/device_transfer/transfer_data_command.dart';
import '../utils/extension/extension.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../widgets/message/send_message_dialog/attachment_extra.dart';
import 'device_transfer.dart';
import 'injector.dart';
import 'isolate_event.dart';
import 'job/ack_job.dart';
import 'job/sending_job.dart';
import 'job/update_asset_job.dart';
import 'job/update_sticker_job.dart';
import 'message_worker_isolate.dart';
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
    this._isolateEventSender,
    this.identityNumber,
    this._ackJob,
    this._sendingJob,
    this._updateStickerJob,
    this._updateAssetJob,
    this._deviceTransfer,
    this._signalDatabase,
  ) : super(userId, database, client) {
    _encryptedProtocol = EncryptedProtocol();
  }

  final void Function(WorkerIsolateEventType event, [dynamic argument])
      _isolateEventSender;

  String? _conversationId;
  late final SignalProtocol _signalProtocol;
  late final Sender _sender;
  late final String _sessionId;
  late final PrivateKey _privateKey;
  late EncryptedProtocol _encryptedProtocol;

  final String identityNumber;
  final AckJob _ackJob;
  final SendingJob _sendingJob;
  final UpdateStickerJob _updateStickerJob;
  final UpdateAssetJob _updateAssetJob;
  final DeviceTransferIsolateController? _deviceTransfer;
  final SignalDatabase _signalDatabase;

  final refreshKeyMap = <String, int?>{};

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
        await database.messageHistoryDao.findMessageHistoryById(messageId);
    return messageHistory != null;
  }

  Future<void> _insertMessage(Message message, BlazeMessageData data) async {
    await database.messageDao.insert(message, accountId,
        silent: data.silent, expireIn: data.expireIn);
    unawaited(database.ftsDatabase.insertFts(message));
    if (data.expireIn > 0 && message.userId == accountId) {
      final expiredAt =
          data.createdAt.millisecondsSinceEpoch ~/ 1000 + data.expireIn;
      await database.expiredMessageDao
          .updateMessageExpireAt(expiredAt, message.messageId);
    }
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
        await _insertMessage(message, data);
      } else if (category.isSignal) {
        d('DecryptMessage isSignal');
        if (data.category == MessageCategory.signalKey) {
          _remoteStatus = MessageStatus.read;
          await database.messageHistoryDao
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

    final messageId = floodMessage.messageId;
    final pendingMessageStatus = pendingMessageStatusMap.remove(messageId);
    if (pendingMessageStatus != null &&
        pendingMessageStatus.index > _remoteStatus.index) {
      _remoteStatus = pendingMessageStatus;
    }

    await _updateRemoteMessageStatus(
      messageId,
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
          final plain = utf8.decode(plaintext, allowMalformed: true);
          if (composeMessageData.resendMessageId != null) {
            await _processReDecryptMessage(
                data, composeMessageData.resendMessageId!, plain);
            await database.messageHistoryDao
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
        final status = (await _signalDatabase.ratchetSenderKeyDao
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
        await _signalDatabase.ratchetSenderKeyDao.deleteByGroupIdAndSenderId(
            data.conversationId,
            SignalProtocolAddress(data.senderId, deviceId).toString());
      } else {
        await _insertFailedMessage(data);
        final address = SignalProtocolAddress(data.senderId, deviceId);
        final status = (await _signalDatabase.ratchetSenderKeyDao
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
          _jsonDecode(data.data) as Map<String, dynamic>);
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
      } else if (plainJsonMessage.action == kDeviceTransfer) {
        final json =
            jsonDecode(plainJsonMessage.content!) as Map<String, dynamic>;
        final command = TransferDataCommand.fromJson(json);
        if (_deviceTransfer == null) {
          e('DeviceTransfer is null, but received command $command');
        }
        i('on device transfer command: $command');
        _deviceTransfer?.handleRemoteCommand(command);
      }
      await database.messageHistoryDao
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
        final plainText = utf8.decode(decryptedContent, allowMalformed: true);
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
      await _sendingJob.add(await database.jobDao.createSendingJob(
        id,
        data.conversationId,
        expireIn: data.expireIn,
      ));
    }
  }

  Future<void> _processSystemMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.systemConversation) {
      final systemMessage = SystemConversationMessage.fromJson(
          _jsonDecode(data.data) as Map<String, dynamic>);
      await _processSystemConversationMessage(data, systemMessage);
    } else if (data.category == MessageCategory.systemUser) {
      final systemMessage = SystemUserMessage.fromJson(
          _jsonDecode(data.data) as Map<String, dynamic>);
      await _processSystemUserMessage(systemMessage);
    } else if (data.category == MessageCategory.systemCircle) {
      final systemMessage = SystemCircleMessage.fromJson(
          _jsonDecode(data.data) as Map<String, dynamic>);
      await _processSystemCircleMessage(data, systemMessage);
    } else if (data.category == MessageCategory.systemAccountSnapshot) {
      final systemSnapshot = SnapshotMessage.fromJson(
          _jsonDecode(data.data) as Map<String, dynamic>);
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
    final content = _decode(data.data);
    // final apps = (await _decode(data.data) as List)
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
    await _insertMessage(message, data);
  }

  Future<void> _processAppCard(BlazeMessageData data) async {
    await refreshUsers(<String>[data.userId]);
    final content = _decode(data.data);
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
    await _insertMessage(message, data);
  }

  Future<void> _processPinMessage(BlazeMessageData data) async {
    final pinMessage = PinMessagePayload.fromJson(
        _jsonDecode(data.data) as Map<String, dynamic>);

    if (pinMessage.action == PinMessagePayloadAction.pin) {
      await futureForEachIndexed(pinMessage.messageIds,
          (index, messageId) async {
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
            messageId: index == 0 ? data.messageId : const Uuid().v4(),
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
      _isolateEventSender(
        WorkerIsolateEventType.showPinMessage,
        data.conversationId,
      );
    } else if (pinMessage.action == PinMessagePayloadAction.unpin) {
      await database.pinMessageDao.deleteByIds(pinMessage.messageIds);
    }

    await database.messageHistoryDao
        .insert(MessagesHistoryData(messageId: data.messageId));
  }

  Future<void> _processRecallMessage(BlazeMessageData data) async {
    final recallMessage =
        RecallMessage.fromJson(_jsonDecode(data.data) as Map<String, dynamic>);
    final message = await database.messageDao
        .findMessageByMessageId(recallMessage.messageId);

    await database.messageDao
        .recallMessage(data.conversationId, recallMessage.messageId);

    unawaited(database.ftsDatabase.deleteByMessageId(recallMessage.messageId));

    await Future.wait([
      (() async {
        if (message != null && message.category.isAttachment) {
          _isolateEventSender(
            WorkerIsolateEventType.requestDownloadAttachment,
            AttachmentCancelRequest(
              messageId: message.messageId,
            ),
          );
          if (message.mediaUrl?.isNotEmpty ?? false) {
            final file = File(message.mediaUrl!);
            final exists = file.existsSync();
            if (exists) {
              await file.delete();
            }
          }
        }
      })(),
      (() async {
        final quoteMessage = await database.messageDao
            .findMessageItemById(data.conversationId, recallMessage.messageId);
        if (quoteMessage != null) {
          await database.messageDao.updateQuoteContentByQuoteId(
              data.conversationId,
              recallMessage.messageId,
              quoteMessage.toJson());
        }
      })(),
      database.messageMentionDao.deleteMessageMention(MessageMention(
        messageId: recallMessage.messageId,
        conversationId: data.conversationId,
      )),
      database.messageHistoryDao
          .insert(MessagesHistoryData(messageId: data.messageId)),
    ]);
  }

  Future<Message> _generateMessage(
      BlazeMessageData data, MessageGenerator generator) async {
    if (data.quoteMessageId == null || (data.quoteMessageId?.isEmpty ?? true)) {
      return generator(null);
    }

    final quoteMessage = await database.messageDao
        .findMessageItemById(data.conversationId, data.quoteMessageId!);

    return quoteMessage != null ? generator(quoteMessage) : generator(null);
  }

  Future<void> _processDecryptSuccess(
    BlazeMessageData data,
    String plainText,
  ) async {
    await refreshUsers(<String>[data.senderId]);

    if (data.category.isText) {
      final plain = data.category == MessageCategory.signalText ||
              data.category == MessageCategory.encryptedText
          ? plainText
          : _decode(plainText);
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
      await _insertMessage(message, data);
    } else if (data.category.isImage) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final content = await jsonEncodeWithIsolate(AttachmentExtra(
              attachmentId: attachment.attachmentId,
              messageId: data.messageId,
              shareable: attachment.shareable)
          .toJson());
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: content,
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
      await _insertMessage(message, data);
      _isolateEventSender(WorkerIsolateEventType.requestDownloadAttachment,
          AttachmentDownloadRequest(message));
    } else if (data.category.isVideo) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final content = await jsonEncodeWithIsolate(AttachmentExtra(
              attachmentId: attachment.attachmentId,
              messageId: data.messageId,
              shareable: attachment.shareable)
          .toJson());
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: content,
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
      await _insertMessage(message, data);
      _isolateEventSender(WorkerIsolateEventType.requestDownloadAttachment,
          AttachmentDownloadRequest(message));
    } else if (data.category.isData) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final content = await jsonEncodeWithIsolate(AttachmentExtra(
              attachmentId: attachment.attachmentId,
              messageId: data.messageId,
              shareable: attachment.shareable)
          .toJson());
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: content,
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
      await _insertMessage(message, data);
      _isolateEventSender(WorkerIsolateEventType.requestDownloadAttachment,
          AttachmentDownloadRequest(message));
    } else if (data.category.isAudio) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
      final attachment = AttachmentMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final content = await jsonEncodeWithIsolate(AttachmentExtra(
              attachmentId: attachment.attachmentId,
              messageId: data.messageId,
              shareable: attachment.shareable)
          .toJson());
      final message = await _generateMessage(
          data,
          (QuoteMessageItem? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: content,
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
      await _insertMessage(message, data);
      _isolateEventSender(WorkerIsolateEventType.requestDownloadAttachment,
          AttachmentDownloadRequest(message));
    } else if (data.category.isSticker) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
      final stickerMessage = StickerMessage.fromJson(
          await jsonDecode(plain) as Map<String, dynamic>);
      final sticker = await database.stickerDao
          .sticker(stickerMessage.stickerId)
          .getSingleOrNull();
      if (sticker == null ||
          (stickerMessage.albumId != null &&
              (sticker.albumId?.isEmpty ?? true))) {
        await _updateStickerJob
            .add(createUpdateStickerJob(stickerMessage.stickerId));
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
      await _insertMessage(message, data);
    } else if (data.category.isContact) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
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
      await _insertMessage(message, data);
    } else if (data.category.isLive) {
      final plain = data.category.isEncrypted ? plainText : _decode(plainText);
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
        createdAt: data.createdAt,
        content: plain,
      );
      await _insertMessage(message, data);
    } else if (data.category.isLocation) {
      final plain = data.category == MessageCategory.signalLocation ||
              data.category == MessageCategory.encryptedLocation
          ? plainText
          : _decode(plainText);
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
      await _insertMessage(message, data);
    } else if (data.category.isPost) {
      final plain = data.category == MessageCategory.signalPost ||
              data.category == MessageCategory.encryptedPost
          ? plainText
          : _decode(plainText);
      final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.senderId,
        category: data.category!,
        content: plain,
        status: data.status,
        createdAt: data.createdAt,
      );
      await _insertMessage(message, data);
    } else if (data.category.isTranscript) {
      final plain = data.category == MessageCategory.signalTranscript ||
              data.category == MessageCategory.encryptedTranscript
          ? plainText
          : _decode(plainText);
      final list = jsonDecode(plain) as List<dynamic>;
      final message = await processTranscriptMessage(data, list);
      if (message != null) {
        await _insertMessage(message, data);
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
      await database.userDao.insert(const db.User(
        userId: systemUser,
        identityNumber: '0',
      ));
    }
    var message = db.Message(
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
    } else if (systemMessage.action == MessageAction.expire) {
      message = message.copyWith(
        content: Value(systemMessage.expireIn.toString()),
      );
      await database.conversationDao.updateConversationExpireIn(
        data.conversationId,
        systemMessage.expireIn,
      );
    }
    await _insertMessage(message, data);
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
          .deleteById(conversationId, systemMessage.circleId);
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
      snapshotHash: snapshotMessage.snapshotHash,
      openingBalance: snapshotMessage.openingBalance,
      closingBalance: snapshotMessage.closingBalance,
    );
    await database.snapshotDao.insert(snapshot);
    await _updateAssetJob.add(createUpdateAssetJob(snapshotMessage.assetId));
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
    await _insertMessage(message, data);
  }

  Future<void> _updateRemoteMessageStatus(
      String messageId, MessageStatus status) async {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    await _ackJob
        .add([createAckJob(kAcknowledgeMessageReceipts, messageId, status)]);
  }

  Future<void> _markMessageStatus(List<BlazeAckMessage> messages) async {
    // key: messageId, value: message expired.
    final messagesWithExpiredAt = <(String, int?)>[];
    messages
        .where((m) => m.status == 'READ' || m.status == 'MENTION_READ')
        .forEach((m) async {
      if (m.status == 'MENTION_READ') {
        await database.messageMentionDao.markMentionRead(m.messageId);
      } else if (m.status == 'READ') {
        messagesWithExpiredAt.add((m.messageId, m.expireAt));
      }
    });

    if (messagesWithExpiredAt.isNotEmpty) {
      final messageIds = messagesWithExpiredAt.map((e) => e.$1).toList();
      final list = await database.messageDao.miniMessageByIds(messageIds).get();

      await database.messageDao.markMessageRead(list, updateExpired: false);
      for (final item in messagesWithExpiredAt) {
        final (messageId, expireAt) = item;
        if (expireAt != null && expireAt > 0) {
          await database.expiredMessageDao
              .updateMessageExpireAt(expireAt, messageId);
        } else {
          final expiredMessage = await database.expiredMessageDao
              .getExpiredMessageById(messageId)
              .getSingleOrNull();
          if (expiredMessage != null) {
            w('expireAt is null or 0. messageId: $messageId');
            await database.expiredMessageDao.onMessageRead([messageId]);
          }
        }
      }
      final set = list.map((e) => e.conversationId).toSet();
      for (final cId in set) {
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
    await _insertMessage(message, data);
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
      await _insertMessage(message, data);
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
          _jsonDecode(plaintext) as Map<String, dynamic>);
      final content = await jsonEncodeWithIsolate(AttachmentExtra(
              attachmentId: attachment.attachmentId,
              messageId: data.messageId,
              shareable: attachment.shareable)
          .toJson());
      final messagesCompanion = MessagesCompanion(
          status: Value(data.status),
          content: Value(content),
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

      final message =
          await database.messageDao.findMessageByMessageId(messageId);

      if (message != null) {
        _isolateEventSender(WorkerIsolateEventType.requestDownloadAttachment,
            AttachmentDownloadRequest(message));
      }
    } else if (data.category == MessageCategory.signalSticker) {
      final plain = _decode(plaintext);
      final stickerMessage = StickerMessage.fromJson(
        jsonDecode(plain) as Map<String, dynamic>,
      );
      final sticker = await database.stickerDao
          .sticker(stickerMessage.stickerId)
          .getSingleOrNull();
      if (sticker == null ||
          (stickerMessage.albumId != null &&
              (sticker.albumId?.isEmpty ?? true))) {
        await _updateStickerJob
            .add(createUpdateStickerJob(stickerMessage.stickerId));
      }
      await database.messageDao.updateStickerMessage(
          messageId, data.status, stickerMessage.stickerId);
    } else if (data.category == MessageCategory.signalContact) {
      final plain = _decode(plaintext);
      final contactMessage = ContactMessage.fromJson(
        jsonDecode(plain) as Map<String, dynamic>,
      );
      await database.messageDao
          .updateContactMessage(messageId, data.status, contactMessage.userId);
    } else if (data.category == MessageCategory.signalLive) {
      final plain = _decode(plaintext);
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
      final plain = _decode(plaintext);
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
    final encoded = _jsonEncode(plainJsonMessage);
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
      await _signalDatabase.ratchetSenderKeyDao.insertSenderKey(ratchet);
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
    final encoded = _jsonEncode(plainJsonMessage);
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, userId, encoded,
        sessionId: sessionId));
    unawaited(_sender.deliver(bm));
    await _signalDatabase.ratchetSenderKeyDao.deleteByGroupIdAndSenderId(
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
    final bm = createSyncSignalKeys(createSyncSignalKeysParam(
        await generateKeys(_signalDatabase, CryptoKeyValue())));
    final result = await _sender.signalKeysChannel(bm);
    if (result == null) {
      i('Registering new pre keys...');
    }
  }

  Future<Message?>? processTranscriptMessage(
      BlazeMessageData data, List<dynamic> list) async {
    final transcripts = list
        .map((e) {
          final json = e as Map<String, dynamic>;

          json['created_at'] =
              DateTime.tryParse(json['created_at'] as String? ?? '')
                  ?.millisecondsSinceEpoch;
          json['media_created_at'] =
              DateTime.tryParse(json['media_created_at'] as String? ?? '')
                  ?.millisecondsSinceEpoch;
          final mediaDuration = json['media_duration'];
          json['media_duration'] =
              mediaDuration != null ? '$mediaDuration' : null;
          json.remove('media_status');

          return TranscriptMessage.fromJson(json);
        })
        .where((transcript) => transcript.transcriptId == data.messageId)
        .whereNotNull()
        .toList();

    if (transcripts.isEmpty) {
      await _insertInvalidMessage(data);
      return null;
    }

    Future _refreshSticker() => Future.wait(transcripts
            .where((transcript) =>
                transcript.category.isSticker &&
                (transcript.stickerId?.isNotEmpty ?? false))
            .map((transcript) async {
          final hasSticker =
              await database.stickerDao.hasSticker(transcript.stickerId!);
          if (hasSticker) return;
          await _updateStickerJob
              .add(createUpdateStickerJob(transcript.stickerId!));
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

    final insertAllTranscriptMessageFuture =
        database.transcriptMessageDao.insertAll(transcripts.map((transcript) {
      if (transcript.category.isAttachment) {
        return transcript.copyWith(
          mediaStatus: const Value(MediaStatus.canceled),
        );
      }
      return transcript;
    }).toList());

    await Future.wait([
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

    final needDownload = transcripts.any((e) => e.category.isAttachment);

    final mediaStatus = (totalMediaSize == 0 || !needDownload)
        ? MediaStatus.done
        : MediaStatus.canceled;

    transcripts.forEach((message) {
      if (message.category.isAttachment && message.content != null) {
        _isolateEventSender(WorkerIsolateEventType.requestDownloadAttachment,
            TranscriptAttachmentDownloadRequest(message));
      }
    });

    final message = Message(
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

    unawaited(Future.sync(() async {
      final content = await database.transcriptMessageDao
          .generateTranscriptMessageFts5Content(transcripts);
      await database.ftsDatabase.insertFts(message, content);
    }));

    return message;
  }
}

dynamic _jsonDecode(String encoded) => jsonDecode(_decode(encoded));

String _decode(String encoded) =>
    utf8.decode(base64Decode(encoded), allowMalformed: true);

String _jsonEncode(Object object) =>
    base64Encode(utf8.encode(jsonEncode(object)));

typedef MessageGenerator = Message Function(QuoteMessageItem? quoteMessageItem);
