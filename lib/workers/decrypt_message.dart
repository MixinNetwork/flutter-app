import 'dart:convert';

import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
// ignore: implementation_imports
import 'package:mixin_bot_sdk_dart/src/vo/signal_key_count.dart';
import 'package:moor/moor.dart';
import 'package:uuid/uuid.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../blaze/blaze_message.dart';
import '../blaze/vo/app_card.dart';
import '../blaze/vo/attachment_message.dart';
import '../blaze/vo/blaze_message_data.dart';
import '../blaze/vo/contact_message.dart';
import '../blaze/vo/live_message.dart';
import '../blaze/vo/location_message.dart';
import '../blaze/vo/plain_json_message.dart';
import '../blaze/vo/recall_message.dart';
import '../blaze/vo/snapshot_message.dart';
import '../blaze/vo/sticker_message.dart';
import '../blaze/vo/system_circle_message.dart';
import '../blaze/vo/system_conversation_message.dart';
import '../blaze/vo/system_user_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/signal/ratchet_status.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/extension/message.dart' show QueteMessage;
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
import '../db/mixin_database.dart' as db;
import '../enum/media_status.dart';
import '../enum/message_action.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../enum/system_circle_action.dart';
import '../enum/system_user_action.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/attachment_util.dart';
import '../utils/dao_extension.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/string_extension.dart';
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
    this.multiAuthCubit,
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
  final MultiAuthCubit multiAuthCubit;

  final refreshKeyMap = <String, int?>{};

  bool get _photoAutoDownload =>
      multiAuthCubit.state.current?.photoAutoDownload ?? true;

  bool get _videoAutoDownload =>
      multiAuthCubit.state.current?.videoAutoDownload ?? true;

  bool get _fileAutoDownload =>
      multiAuthCubit.state.current?.fileAutoDownload ?? true;

  set conversationId(String? conversationId) {
    _conversationId = conversationId;
  }

  late MessageStatus _remoteStatus;

  Future<void> process(FloodMessage floodMessage) async {
    final data = BlazeMessageData.fromJson(
        await jsonDecodeWithIsolate(floodMessage.data));
    d('DecryptMessage process data: ${data.toJson()}');
    try {
      var status = MessageStatus.delivered;
      _remoteStatus = MessageStatus.delivered;
      if (_conversationId == data.conversationId) {
        _remoteStatus = MessageStatus.read;
        status = MessageStatus.read;
      }

      await syncConversion(data.conversationId);
      final category = data.category;
      if (category.isSignal) {
        d('DecryptMessage isSignal');
        if (data.category == MessageCategory.signalKey) {
          _remoteStatus = MessageStatus.read;
        }
        await _processSignalMessage(data, status);
      } else if (category.isPlain) {
        d('DecryptMessage isPlain');
        await _processPlainMessage(data, status);
      } else if (category.isEncrypted) {
        d('DecryptMessage isEncrypted');
        await _processEncryptedMessage(data, status);
      } else if (category.isSystem) {
        d('DecryptMessage isSystem');
        _remoteStatus = MessageStatus.read;
        await _processSystemMessage(data, status);
      } else if (category == MessageCategory.appButtonGroup ||
          category == MessageCategory.appCard) {
        d('DecryptMessage isApp');
        await _processApp(data, status);
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

    await database.floodMessagesDao.deleteFloodMessage(floodMessage);
  }

  Future<void> _processSignalMessage(
      BlazeMessageData data, MessageStatus messageStatus) async {
    final deviceId = data.sessionId.getDeviceId();
    final composeMessageData = _signalProtocol.decodeMessageData(data.data);
    try {
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
          } else {
            await _processDecryptSuccess(data, plain, messageStatus);
          }
        }

        final address = SignalProtocolAddress(data.senderId, deviceId);
        final status = (await SignalDatabase.get.ratchetSenderKeyDao
                .getRatchetSenderKey(data.conversationId, address.toString()))
            ?.status;
        if (status == RatchetStatus.requesting.toString()) {
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

  Future<void> _processPlainMessage(
      BlazeMessageData data, MessageStatus status) async {
    if (data.category == MessageCategory.plainJson) {
      final plainJsonMessage =
          PlainJsonMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
      if (plainJsonMessage.action == acknowledgeMessageReceipts &&
          plainJsonMessage.ackMessages?.isNotEmpty == true) {
        await _markMessageStatus(plainJsonMessage.ackMessages!);
      } else if (plainJsonMessage.action == resendMessages) {
        await _processResendMessage(data, plainJsonMessage);
      } else if (plainJsonMessage.action == resendKey) {
        if (await _signalProtocol.containsUserSession(data.userId)) {
          unawaited(_sender.sendProcessSignalKey(
              data, ProcessSignalKeyAction.resendKey));
        }
      }
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
      await _processDecryptSuccess(data, data.data, status);
    }
  }

  Future<void> _processEncryptedMessage(
      BlazeMessageData data, MessageStatus status) async {
    try {
      final decryptedContent = _encryptedProtocol.decryptMessage(_privateKey,
          Uuid.parse(_sessionId), await base64DecodeWithIsolate(data.data));
      if (decryptedContent == null) {
        // todo
      } else {
        final plainText = await utf8DecodeWithIsolate(decryptedContent);
        try {
          await _processDecryptSuccess(data, plainText, status);
        } catch (e) {
          // todo insertInvalidMessage
        }
      }
    } catch (e) {
      // todo
      w(e.toString());
    }
  }

  Future<void> _processResendMessage(
      BlazeMessageData data, PlainJsonMessage plainData) async {
    final messages = plainData.messages;
    if (messages == null) {
      return;
    }
    final p = await database.participantsDao
        .findParticipantById(data.conversationId, data.userId)
        .getSingleOrNull();
    if (p == null) {
      return;
    }
    for (final id in messages) {
      final resendMessage = await database.resendSessionMessagesDao
          .findResendMessage(data.userId, data.sessionId, id);
      if (resendMessage != null) {
        continue;
      }
      final needResendMessage = await database.messagesDao
          .findMessageByMessageIdAndUserId(id, accountId);
      if (needResendMessage == null ||
          needResendMessage.category == MessageCategory.messageRecall) {
        await database.resendSessionMessagesDao.insert(ResendSessionMessage(
            messageId: id,
            userId: data.userId,
            sessionId: data.sessionId,
            status: 0,
            createdAt: DateTime.now()));
        continue;
      }
      if (p.createdAt.isAfter(needResendMessage.createdAt)) {
        continue;
      }
      await database.resendSessionMessagesDao.insert(ResendSessionMessage(
          messageId: id,
          userId: data.userId,
          sessionId: data.sessionId,
          status: 1,
          createdAt: DateTime.now()));
      await database.jobsDao.insertSendingJob(id, data.conversationId);
    }
  }

  Future<void> _processSystemMessage(
      BlazeMessageData data, MessageStatus status) async {
    if (data.category == MessageCategory.systemConversation) {
      final systemMessage = SystemConversationMessage.fromJson(
          await _jsonDecodeWithIsolate(data.data));
      await _processSystemConversationMessage(data, systemMessage, status);
    } else if (data.category == MessageCategory.systemUser) {
      final systemMessage =
          SystemUserMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
      await _processSystemUserMessage(systemMessage);
    } else if (data.category == MessageCategory.systemCircle) {
      final systemMessage =
          SystemCircleMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
      await _processSystemCircleMessage(data, systemMessage);
    } else if (data.category == MessageCategory.systemAccountSnapshot) {
      final systemSnapshot =
          SnapshotMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
      await _processSystemSnapshotMessage(data, systemSnapshot);
    }
  }

  Future<void> _processApp(BlazeMessageData data, MessageStatus status) async {
    d('data.conversationId: ${data.conversationId}, _conversationId: $_conversationId');
    if (data.category == MessageCategory.appButtonGroup) {
      await _processAppButton(data, status);
    } else if (data.category == MessageCategory.appCard) {
      await _processAppCard(data, status);
    }
  }

  Future<void> _processAppButton(
      BlazeMessageData data, MessageStatus status) async {
    final content = await _decodeWithIsolate(data.data);
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
      status: status,
      createdAt: data.createdAt,
    );
    await database.messagesDao.insert(message, accountId);
  }

  Future<void> _processAppCard(
      BlazeMessageData data, MessageStatus status) async {
    await refreshUsers(<String>[data.userId]);
    final content = await _decodeWithIsolate(data.data);
    final appCard = AppCard.fromJson(await jsonDecodeWithIsolate(content));
    final message = Message(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.senderId,
      category: data.category!,
      content: content,
      status: status,
      createdAt: data.createdAt,
    );
    await database.appsDao.findUserById(appCard.appId).then((app) {
      if (app == null || app.updatedAt != appCard.updatedAt) {
        refreshUsers(<String>[appCard.appId]);
      }
    });
    await database.messagesDao.insert(message, accountId);
  }

  Future<void> _processRecallMessage(BlazeMessageData data) async {
    final recallMessage =
        RecallMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
    await database.messagesDao.recallMessage(recallMessage.messageId);
  }

  Future<Message> _generateMessage(
      BlazeMessageData data, MessageGenerator generator) async {
    if (data.quoteMessageId == null || (data.quoteMessageId?.isEmpty ?? true)) {
      return generator(null);
    }

    final quoteMessage = await database.messagesDao
        .findMessageItemById(data.conversationId, data.quoteMessageId!);

    if (quoteMessage != null) {
      return generator(quoteMessage.toJson());
    } else {
      return generator(null);
    }
  }

  Future<void> _processDecryptSuccess(
    BlazeMessageData data,
    String plainText,
    MessageStatus status,
  ) async {
    await refreshUsers(<String>[data.senderId]);

    if (data.category.isText) {
      String plain;
      if (data.category == MessageCategory.signalText) {
        plain = plainText;
      } else {
        plain = await _decodeWithIsolate(plainText);
      }
      final message = await _generateMessage(
          data,
          (String? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: plain,
              status: status,
              createdAt: data.createdAt,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      if (message.content?.isNotEmpty ?? false) {
        await database.messageMentionsDao.parseMentionData(
          message.content!,
          message.messageId,
          message.conversationId,
          data.senderId,
        );
      }
      await database.messagesDao.insert(message, accountId);
    } else if (data.category.isImage) {
      final attachment =
          AttachmentMessage.fromJson(await _jsonDecodeWithIsolate(plainText));
      final message = await _generateMessage(
          data,
          (String? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              mediaUrl: null,
              mediaMimeType: attachment.mimeType,
              mediaSize: attachment.size,
              mediaWidth: attachment.width,
              mediaHeight: attachment.height,
              thumbImage: attachment.thumbnail,
              mediaKey: attachment.key,
              mediaDigest: attachment.digest,
              status: status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.canceled,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      await database.messagesDao.insert(message, accountId);
      if (_photoAutoDownload) {
        unawaited(_attachmentUtil.downloadAttachment(
          messageId: message.messageId,
          conversationId: message.conversationId,
          category: message.category,
          content: message.content!,
          key: attachment.key,
          digest: attachment.digest,
          mimeType: attachment.mimeType,
        ));
      }
    } else if (data.category.isVideo) {
      final plain = await _decodeWithIsolate(plainText);
      final attachment =
          AttachmentMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final message = await _generateMessage(
          data,
          (String? quoteContent) => Message(
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
              mediaKey: attachment.key,
              mediaDigest: attachment.digest,
              status: status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.canceled,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      await database.messagesDao.insert(message, accountId);
      if (_videoAutoDownload) {
        unawaited(_attachmentUtil.downloadAttachment(
          messageId: message.messageId,
          conversationId: message.conversationId,
          category: message.category,
          content: message.content!,
          key: attachment.key,
          digest: attachment.digest,
          mimeType: attachment.mimeType,
        ));
      }
    } else if (data.category.isData) {
      final plain = await _decodeWithIsolate(plainText);
      final attachment =
          AttachmentMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final message = await _generateMessage(
          data,
          (String? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              name: attachment.name,
              mediaMimeType: attachment.mimeType,
              mediaSize: attachment.size,
              mediaKey: attachment.key,
              mediaDigest: attachment.digest,
              status: status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.canceled,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      await database.messagesDao.insert(message, accountId);
      if (_fileAutoDownload) {
        unawaited(_attachmentUtil.downloadAttachment(
          messageId: message.messageId,
          conversationId: message.conversationId,
          category: message.category,
          content: message.content!,
          key: attachment.key,
          digest: attachment.digest,
          mimeType: attachment.mimeType,
        ));
      }
    } else if (data.category.isAudio) {
      final plain = await _decodeWithIsolate(plainText);
      final attachment =
          AttachmentMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final message = await _generateMessage(
          data,
          (String? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: attachment.attachmentId,
              name: attachment.name,
              mediaMimeType: attachment.mimeType,
              mediaSize: attachment.size,
              mediaKey: attachment.key,
              mediaDigest: attachment.digest,
              mediaWaveform: attachment.waveform,
              status: status,
              createdAt: data.createdAt,
              mediaStatus: MediaStatus.pending,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      await database.messagesDao.insert(message, accountId);
      unawaited(_attachmentUtil.downloadAttachment(
        messageId: message.messageId,
        conversationId: message.conversationId,
        category: message.category,
        content: message.content!,
        key: attachment.key,
        digest: attachment.digest,
        mimeType: attachment.mimeType,
      ));
    } else if (data.category.isSticker) {
      final plain = await _decodeWithIsolate(plainText);
      final stickerMessage =
          StickerMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final sticker = await database.stickerDao
          .getStickerByUnique(stickerMessage.stickerId);
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
          status: status,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message, accountId);
    } else if (data.category.isContact) {
      final plain = await _decodeWithIsolate(plainText);
      final contactMessage =
          ContactMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final user = (await refreshUsers(<String>[contactMessage.userId]))?.first;
      final message = await _generateMessage(
          data,
          (String? quoteContent) => Message(
              messageId: data.messageId,
              conversationId: data.conversationId,
              userId: data.senderId,
              category: data.category!,
              content: plainText,
              name: user?.fullName,
              sharedUserId: contactMessage.userId,
              status: status,
              createdAt: data.createdAt,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      await database.messagesDao.insert(message, accountId);
    } else if (data.category.isLive) {
      final plain = await _decodeWithIsolate(plainText);
      final liveMessage =
          LiveMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          mediaWidth: liveMessage.width,
          mediaHeight: liveMessage.height,
          mediaUrl: liveMessage.url,
          thumbUrl: liveMessage.thumbUrl,
          status: status,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message, accountId);
    } else if (data.category.isLocation) {
      String plain;
      if (data.category == MessageCategory.signalLocation) {
        plain = plainText;
      } else {
        plain = await _decodeWithIsolate(plainText);
      }
      // ignore: unused_local_variable todo check location
      LocationMessage? locationMessage;
      try {
        locationMessage =
            LocationMessage.fromJson(await jsonDecodeWithIsolate(plain));
      } catch (e) {
        w('decode locationMessage error $e');
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
          status: status,
          createdAt: data.createdAt);
      await database.messagesDao.insert(message, accountId);
    } else if (data.category.isPost) {
      String plain;
      if (data.category == MessageCategory.signalPost) {
        plain = plainText;
      } else {
        plain = await _decodeWithIsolate(plainText);
      }
      final message = Message(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.senderId,
        category: data.category!,
        content: plain,
        status: status,
        createdAt: data.createdAt,
      );
      await database.messagesDao.insert(message, accountId);
    }
  }

  Future<void> _processSystemConversationMessage(BlazeMessageData data,
      SystemConversationMessage systemMessage, MessageStatus status) async {
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
        status: status,
        action: systemMessage.action,
        participantId: systemMessage.participantId);
    if (systemMessage.action == MessageAction.add ||
        systemMessage.action == MessageAction.join) {
      await database.participantsDao.insert(db.Participant(
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
      await database.participantsDao.updateParticipantRole(
        data.conversationId,
        systemMessage.participantId!,
        systemMessage.role,
      );
      if (systemMessage.participantId != accountId) {
        return;
      }
    }
    await database.messagesDao.insert(message, accountId);
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
          await database.circlesDao.findCircleById(systemMessage.circleId);
      if (circle == null) {
        unawaited(refreshCircle(circleId: systemMessage.circleId));
      }
      final conversationId = systemMessage.conversationId;
      await refreshUsers(<String>[systemMessage.userId]);
      await database.circleConversationDao.insert(db.CircleConversation(
        conversationId: conversationId,
        circleId: systemMessage.circleId,
        userId: systemMessage.userId,
        createdAt: data.createdAt,
      ));
    } else if (systemMessage.action == SystemCircleAction.remove) {
      final conversationId = systemMessage.conversationId;
      await database.circleConversationDao
          .deleteByIds(conversationId, systemMessage.circleId);
    } else if (systemMessage.action == SystemCircleAction.delete) {
      await database.circlesDao.deleteCircleById(systemMessage.circleId);
      await database.circleConversationDao
          .deleteByCircleId(systemMessage.circleId);
    }
  }

  Future<void> _processSystemSnapshotMessage(
      BlazeMessageData data, SnapshotMessage snapshotMessage) async {
    final snapshot = Snapshot(
        snapshotId: snapshotMessage.snapshotId,
        type: snapshotMessage.type,
        assetId: snapshotMessage.assetId,
        amount: snapshotMessage.amount,
        createdAt: DateTime.parse(snapshotMessage.createdAt));
    await database.snapshotsDao.insert(snapshot);
    final exists = await database.assetsDao.findAssetById(snapshot.assetId);
    if (exists == null) {
      final a =
          (await client.assetApi.getAssetById(snapshotMessage.assetId)).data;
      final asset = Asset(
          assetId: a.assetId,
          symbol: a.symbol,
          name: a.name,
          iconUrl: a.iconUrl,
          balance: a.balance,
          destination: a.destination,
          priceBtc: a.priceBtc,
          priceUsd: a.priceUsd,
          chainId: a.chainId,
          changeUsd: a.changeUsd,
          changeBtc: a.changeBtc,
          confirmations: a.confirmations);
      await database.assetsDao.insert(asset);
    }
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
    await database.messagesDao.insert(message, accountId);
  }

  Future<void> _updateRemoteMessageStatus(
      messageId, MessageStatus status) async {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    await database.jobsDao.insertNoReplace(
        createAckJob(acknowledgeMessageReceipts, messageId, status));
    if (status == MessageStatus.read) {
      await database.jobsDao
          .insert(createAckJob(createMessage, messageId, MessageStatus.read));
    }
  }

  Future<void> _markMessageStatus(List<BlazeAckMessage> messages) async {
    final messageIds = <String>[];
    messages
        .takeWhile((m) => m.status != 'READ' || m.status != 'MENTION_READ')
        .forEach((m) {
      if (m.status == 'MENTION_READ') {
      } else {
        messageIds.add(m.messageId);
      }
    });

    if (messageIds.isNotEmpty) {
      await database.messagesDao.markMessageRead(accountId, messageIds);
      final conversationIds =
          await database.messagesDao.findConversationIdsByMessages(messageIds);
      for (var cId in conversationIds) {
        await database.messagesDao.takeUnseen(accountId, cId);
      }
    }
  }

  Future<void> _insertInvalidMessage(BlazeMessageData data) async {
    final message = MessagesCompanion.insert(
        messageId: data.messageId,
        conversationId: data.conversationId,
        userId: data.senderId,
        content: Value(data.data),
        category: data.category!,
        status: MessageStatus.unknown,
        createdAt: data.createdAt);
    await database.messagesDao.insertCompanion(message);
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
      await database.messagesDao.insert(message, data.senderId);
    }
  }

  Future<void> _processReDecryptMessage(
      BlazeMessageData data, String messageId, String plaintext) async {
    if (data.category == MessageCategory.signalText) {
      await database.messageMentionsDao.parseMentionData(
        plaintext,
        messageId,
        data.conversationId,
        data.senderId,
      );
      await database.messagesDao
          .updateMessageContentAndStatus(messageId, plaintext, data.status);
    } else if (data.category == MessageCategory.signalPost) {
      await database.messagesDao
          .updateMessageContentAndStatus(messageId, plaintext, data.status);
    } else if (data.category == MessageCategory.signalLocation) {
      await database.messagesDao
          .updateMessageContentAndStatus(messageId, plaintext, data.status);
    } else if (data.category == MessageCategory.signalImage ||
        data.category == MessageCategory.signalVideo ||
        data.category == MessageCategory.signalData ||
        data.category == MessageCategory.signalAudio) {
      final attachment =
          AttachmentMessage.fromJson(await _jsonDecodeWithIsolate(plaintext));
      final messagesCompanion = MessagesCompanion(
          status: Value(data.status),
          content: Value(attachment.attachmentId),
          mediaMimeType: Value(attachment.mimeType),
          mediaSize: Value(attachment.size),
          mediaStatus: const Value(MediaStatus.canceled),
          mediaWidth: Value(attachment.width),
          mediaHeight: Value(attachment.height),
          mediaDigest: Value(attachment.digest),
          mediaKey: Value(attachment.key),
          mediaWaveform: Value(attachment.waveform),
          name: Value(attachment.name),
          thumbImage: Value(attachment.thumbnail),
          mediaDuration: Value(attachment.duration.toString()));
      await database.messagesDao
          .updateAttachmentMessage(messageId, messagesCompanion);
    } else if (data.category == MessageCategory.signalSticker) {
      final plain = await _decodeWithIsolate(plaintext);
      final stickerMessage =
          StickerMessage.fromJson(await jsonDecodeWithIsolate(plain));
      final sticker = await database.stickerDao
          .getStickerByUnique(stickerMessage.stickerId);
      if (sticker == null) {
        await refreshSticker(stickerMessage.stickerId);
      }
      await database.messagesDao.updateStickerMessage(
          messageId, data.status, stickerMessage.stickerId);
    } else if (data.category == MessageCategory.signalContact) {
      final plain = await _decodeWithIsolate(plaintext);
      final contactMessage =
          ContactMessage.fromJson(await jsonDecodeWithIsolate(plain));
      await database.messagesDao
          .updateContactMessage(messageId, data.status, contactMessage.userId);
    } else if (data.category == MessageCategory.signalLive) {
      final plain = await _decodeWithIsolate(plaintext);
      final liveMessage =
          LiveMessage.fromJson(await jsonDecodeWithIsolate(plain));
      await database.messagesDao.updateLiveMessage(
          messageId,
          liveMessage.width,
          liveMessage.height,
          liveMessage.url,
          liveMessage.thumbUrl,
          data.status);
    }
    if (await database.messagesDao
            .countMessageByQuoteId(data.conversationId, messageId) >
        0) {
      final messageItem = await database.messagesDao
          .findMessageItemById(data.conversationId, messageId);
      if (messageItem != null) {
        await database.messagesDao.updateQuoteContentByQuoteId(
            data.conversationId, messageId, messageItem.toJson());
      }
    }
  }

  Future<void> _requestResendKey(String conversationId, String recipientId,
      String messageId, String? sessionId) async {
    final plainJsonMessage =
        PlainJsonMessage(resendKey, null, null, messageId, null, null);
    final encoded = await _jsonEncodeWithIsolate(plainJsonMessage);
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, recipientId, encoded,
        sessionId: sessionId));
    unawaited(_sender.deliverNoThrow(bm));
    final address = SignalProtocolAddress(recipientId, sessionId.getDeviceId());
    final ratchet = RatchetSenderKeysCompanion.insert(
        groupId: conversationId,
        senderId: address.toString(),
        status: RatchetStatus.requesting.toString(),
        createdAt: DateTime.now().millisecondsSinceEpoch.toString());
    await SignalDatabase.get.ratchetSenderKeyDao.insertSenderKey(ratchet);
  }

  Future<void> _requestResendMessage(
      String conversationId, String userId, String? sessionId) async {
    final messages =
        await database.messagesDao.findFailedMessages(conversationId, userId);
    if (messages.isEmpty) {
      return;
    }
    final plainJsonMessage = PlainJsonMessage(
        resendMessages, messages.reversed.toList(), null, null, null, null);
    final encoded = await _jsonEncodeWithIsolate(plainJsonMessage);
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, userId, encoded,
        sessionId: sessionId));
    unawaited(_sender.deliverNoThrow(bm));
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
    final count = SignalKeyCount.fromJson(data);
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
}

dynamic _jsonDecode(String encoded) => jsonDecode(_decode(encoded));

String _decode(String encoded) => utf8.decode(base64Decode(encoded));

String _jsonEncode(Object object) =>
    base64Encode(utf8.encode(jsonEncode(object)));

Future<dynamic> _jsonDecodeWithIsolate(String encoded) =>
    runLoadBalancer(_jsonDecode, encoded);

Future<String> _jsonEncodeWithIsolate(Object object) =>
    runLoadBalancer(_jsonEncode, object);

Future<String> _decodeWithIsolate(String encoded) =>
    runLoadBalancer(_decode, encoded);

typedef MessageGenerator = Message Function(String? quoteContent);
