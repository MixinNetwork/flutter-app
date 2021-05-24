import 'dart:convert';

import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
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
import '../blaze/vo/system_session_message.dart';
import '../blaze/vo/system_user_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/signal/ratchet_status.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/database.dart';
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
import '../utils/load_balancer_utils.dart';
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

  Future<void> process(FloodMessage floodMessage) async {
    final data = BlazeMessageData.fromJson(
        await jsonDecodeWithIsolate(floodMessage.data));
    debugPrint('DecryptMessage process data: ${data.toJson()}');
    await syncConversion(data.conversationId);
    final category = data.category;
    if (category.isSignal) {
      debugPrint('DecryptMessage isSignal');
      await _processSignalMessage(data);
    } else if (category.isPlain) {
      debugPrint('DecryptMessage isPlain');
      await _processPlainMessage(data);
    } else if (category.isEncrypted) {
      debugPrint('DecryptMessage isEncrypted');
      await _processEncryptedMessage(data);
    } else if (category.isSystem) {
      debugPrint('DecryptMessage isSystem');
      await _processSystemMessage(data);
    } else if (category == MessageCategory.appButtonGroup ||
        category == MessageCategory.appCard) {
      debugPrint('DecryptMessage isApp');
      await _processApp(data);
    } else if (category == MessageCategory.messageRecall) {
      debugPrint('DecryptMessage isMessageRecall');
      await _processRecallMessage(data);
    }
    await _updateRemoteMessageStatus(
        floodMessage.messageId, MessageStatus.delivered);
    await database.floodMessagesDao.deleteFloodMessage(floodMessage);
  }

  Future<void> _processSignalMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.signalKey) {
      await _updateRemoteMessageStatus(data.messageId, MessageStatus.read);
      // TODO messageHistoryDao.insert
    } else {
      await _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
    }
    final deviceId = data.sessionId.getDeviceId();
    final composeMessageData = _signalProtocol.decodeMessageData(data.data);
    try {
      _signalProtocol.decrypt(
          data.conversationId,
          data.senderId,
          composeMessageData.keyType,
          composeMessageData.cipher,
          data.category?.toString() ?? '',
          data.sessionId, (plaintext) async {
        if (data.category == MessageCategory.signalKey &&
            data.senderId != accountId) {
          // publish sender key change
        }
        if (data.category != MessageCategory.signalKey) {
          final plain = utf8.decode(plaintext);
          if (composeMessageData.resendMessageId != null) {
            // resent
          } else {
            try {
              await _processDecryptSuccess(data, plain);
            } on FormatException catch (e) {
              debugPrint(
                  'decrypt _processDecryptSuccess ${data.messageId}, $e');
              await _insertInvalidMessage(data);
            }
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
      debugPrint('decrypt failed ${data.messageId}, $e');
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
      final plainJsonMessage =
          PlainJsonMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
      if (plainJsonMessage.action == acknowledgeMessageReceipts &&
          plainJsonMessage.ackMessages?.isNotEmpty == true) {
        await _markMessageStatus(plainJsonMessage.ackMessages!);
      } else if (plainJsonMessage.action == resendMessages) {
        // todo
      } else if (plainJsonMessage.action == resendKey) {
        // todo
      }
      await _updateRemoteMessageStatus(data.messageId, MessageStatus.delivered);
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
      await _processDecryptSuccess(data, data.data);
    }
  }

  Future<void> _processEncryptedMessage(BlazeMessageData data) async {
    try {
      final decryptedContent = _encryptedProtocol.decryptMessage(_privateKey,
          Uuid.parse(_sessionId), await base64DecodeWithIsolate(data.data));
      if (decryptedContent == null) {
        // todo
      } else {
        final plainText = await utf8DecodeWithIsolate(decryptedContent);
        try {
          await _processDecryptSuccess(data, plainText);
        } catch (e) {
          // todo insertInvalidMessage
        }
      }
    } catch (e) {
      // todo
      debugPrint(e.toString());
    }
  }

  Future<void> _processSystemMessage(BlazeMessageData data) async {
    if (data.category == MessageCategory.systemConversation) {
      final systemMessage = SystemConversationMessage.fromJson(
          await _jsonDecodeWithIsolate(data.data));
      await _processSystemConversationMessage(data, systemMessage);
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
    } else if (data.category == MessageCategory.systemSession) {
      final systemSession = SystemSessionMessage.fromJson(
          await _jsonDecodeWithIsolate(data.data));
      await _processSystemSessionMessage(systemSession);
    }
    await _updateRemoteMessageStatus(data.messageId, MessageStatus.read);
  }

  Future<void> _processApp(BlazeMessageData data) async {
    debugPrint(
        'data.conversationId: ${data.conversationId}, _conversationId: $_conversationId');
    if (data.category == MessageCategory.appButtonGroup) {
      await _processAppButton(data);
    } else if (data.category == MessageCategory.appCard) {
      await _processAppCard(data);
    } else {
      await _updateRemoteMessageStatus(data.messageId, MessageStatus.read);
    }
  }

  Future<void> _processAppButton(BlazeMessageData data) async {
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
      status: MessageStatus.delivered,
      createdAt: data.createdAt,
    );
    await database.messagesDao.insert(message, accountId);
    var messageStatus = MessageStatus.delivered;
    if (data.conversationId == _conversationId) {
      messageStatus = MessageStatus.read;
    }
    await _updateRemoteMessageStatus(data.messageId, messageStatus);
  }

  Future<void> _processAppCard(BlazeMessageData data) async {
    final content = await _decodeWithIsolate(data.data);
    final appCard = AppCard.fromJson(await jsonDecodeWithIsolate(content));
    final message = Message(
      messageId: data.messageId,
      conversationId: data.conversationId,
      userId: data.senderId,
      category: data.category!,
      content: content,
      status: MessageStatus.delivered,
      createdAt: data.createdAt,
    );
    await database.appsDao.findUserById(appCard.appId).then((app) {
      if (app == null || app.updatedAt != appCard.updatedAt) {
        refreshUsers(<String>[appCard.appId]);
      }
    });
    await database.messagesDao.insert(message, accountId);
    var messageStatus = MessageStatus.delivered;
    if (data.conversationId == _conversationId) {
      messageStatus = MessageStatus.read;
    }
    await _updateRemoteMessageStatus(data.messageId, messageStatus);
  }

  Future<void> _processRecallMessage(BlazeMessageData data) async {
    final recallMessage =
        RecallMessage.fromJson(await _jsonDecodeWithIsolate(data.data));
    await database.messagesDao.recallMessage(recallMessage.messageId);
    await _updateRemoteMessageStatus(data.messageId, MessageStatus.read);
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
      BlazeMessageData data, String plainText) async {
    // todo
    await refreshUsers(<String>[data.senderId]);

    var messageStatus = MessageStatus.delivered;
    if (data.conversationId == _conversationId) {
      messageStatus = MessageStatus.read;
    }

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
              status: messageStatus,
              createdAt: data.createdAt,
              quoteMessageId: data.quoteMessageId,
              quoteContent: quoteContent));
      debugPrint('insert message: ${message.toJson()}');
      await database.messagesDao.insert(message, accountId);
      debugPrint('after insert');
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
              status: messageStatus,
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
              status: messageStatus,
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
            digest: attachment.digest));
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
              status: messageStatus,
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
            digest: attachment.digest));
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
              status: messageStatus,
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
          digest: attachment.digest));
    } else if (data.category.isSticker) {
      final String plain = await _decodeWithIsolate(plainText);
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
          status: messageStatus,
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
              status: messageStatus,
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
          status: messageStatus,
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
        debugPrint(e.toString());
      }
      if (locationMessage == null ||
          locationMessage.latitude == 0.0 ||
          locationMessage.longitude == 0.0) {
        await _updateRemoteMessageStatus(data.messageId, MessageStatus.read);
        return;
      }
      final message = Message(
          messageId: data.messageId,
          conversationId: data.conversationId,
          userId: data.senderId,
          category: data.category!,
          content: plain,
          status: messageStatus,
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
        status: messageStatus,
        createdAt: data.createdAt,
      );
      await database.messagesDao.insert(message, accountId);
    }

    await _updateRemoteMessageStatus(data.messageId, messageStatus);
  }

  Future<void> _processSystemConversationMessage(
      BlazeMessageData data, SystemConversationMessage systemMessage) async {
    if (systemMessage.action != MessageAction.update) {
      await syncConversion(data.conversationId);
    }
    final userId = systemMessage.userId ?? data.senderId;
    if (userId == systemUser &&
        (await database.userDao.findUserById(userId).getSingleOrNull()) ==
            null) {
      // todo UserRelationship
      await database.userDao.insert(db.User(
          userId: systemUser,
          identityNumber: '0',
          relationship: UserRelationship.friend));
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
      // database.participantsDao.insert(db.Participant(conversationId: data.conversationId,userId: systemMessage.participantId, role: '' ,createdAt: data.createdAt));
      // todo refresh conversation and signal key
      if (systemMessage.participantId == accountId) {
        await syncConversion(data.conversationId);
        // } else if (systemMessage.userId != selfId && no signal key) {
      } else {
        // syncSession();
        // syncUser();
      }
    } else if (systemMessage.action == MessageAction.remove ||
        systemMessage.action == MessageAction.exit) {
      if (systemMessage.participantId == accountId) {
        unawaited(database.conversationDao.updateConversationStatusById(
            data.conversationId, ConversationStatus.quit));
      }
      // todo remove signal key
    } else if (systemMessage.action == MessageAction.update) {
      final participantId = systemMessage.participantId;
      if (participantId != null && participantId.isNotEmpty) {
        await refreshUsers(<String>[systemMessage.participantId!], force: true);
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
      if (systemMessage.participantId == accountId) {
        return;
      }
    }
    await database.messagesDao.insert(message, accountId);
  }

  Future<void> _processSystemUserMessage(
      SystemUserMessage systemMessage) async {
    if (systemMessage.action == SystemUserAction.update) {
      await refreshUsers(<String>[systemMessage.userId]);
    }
  }

  Future<void> _processSystemCircleMessage(
      BlazeMessageData data, SystemCircleMessage systemMessage) async {
    if (systemMessage.action == SystemCircleAction.create ||
        systemMessage.action == SystemCircleAction.update) {
      // todo refresh circle
    } else if (systemMessage.action == SystemCircleAction.add) {
    } else if (systemMessage.action == SystemCircleAction.remove) {
    } else if (systemMessage.action == SystemCircleAction.delete) {}
  }

  Future<void> _processSystemSnapshotMessage(
      BlazeMessageData data, SnapshotMessage systemSnapshot) async {
    // todo process snapshot message
  }

  Future<void> _processSystemSessionMessage(
      SystemSessionMessage systemSession) async {
    // todo only run mobile client
  }

  Future<void> _updateRemoteMessageStatus(
      messageId, MessageStatus status) async {
    if (status != MessageStatus.delivered && status != MessageStatus.read) {
      return;
    }
    final blazeMessage = BlazeAckMessage(
        messageId: messageId,
        status: EnumToString.convertToString(status)!.toUpperCase());
    await database.jobsDao.insert(Job(
        jobId: const Uuid().v4(),
        action: acknowledgeMessageReceipts,
        priority: 5,
        blazeMessage: jsonEncode(blazeMessage),
        createdAt: DateTime.now(),
        runCount: 0));
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
      await database.messagesDao.markMessageRead(messageIds);
      // todo refresh conversion
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
        messageId: const Uuid().v4(),
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

  Future<void> _requestResendKey(String conversationId, String recipientId,
      String messageId, String? sessionId) async {
    final plainText =
        PlainJsonMessage(resendKey, null, null, messageId, null, null)
            .toJson()
            .toString();
    final encoded = base64.encode(utf8.encode(plainText));
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
    final plainText = PlainJsonMessage(
            resendMessages, messages.reversed.toList(), null, null, null, null)
        .toJson()
        .toString();
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, userId, base64.encode(utf8.encode(plainText)),
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
      debugPrint('Registering new pre keys...');
    }
  }

  void syncSession() {}
}

dynamic _jsonDecode(String encoded) => jsonDecode(_decode(encoded));

String _decode(String encoded) => utf8.decode(base64Decode(encoded));

Future<dynamic> _jsonDecodeWithIsolate(String encoded) =>
    runLoadBalancer(_jsonDecode, encoded);

Future<String> _decodeWithIsolate(String encoded) =>
    runLoadBalancer(_decode, encoded);

typedef MessageGenerator = Message Function(String? quoteContent);
