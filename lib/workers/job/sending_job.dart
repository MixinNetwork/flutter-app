import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:mixin_logger/mixin_logger.dart';
import 'package:uuid/uuid.dart';

import '../../blaze/blaze_message.dart';
import '../../blaze/blaze_message_param.dart';
import '../../blaze/vo/message_result.dart';
import '../../constants/constants.dart';
import '../../crypto/encrypted/encrypted_protocol.dart';
import '../../crypto/signal/signal_protocol.dart';
import '../../db/converter/utc_value_serializer.dart';
import '../../db/dao/job_dao.dart';
import '../../db/dao/message_dao.dart';
import '../../db/extension/message.dart';
import '../../db/mixin_database.dart';
import '../../enum/message_category.dart';
import '../../utils/extension/extension.dart';
import '../../utils/load_balancer_utils.dart';
import '../../utils/reg_exp_utils.dart';
import '../../widgets/message/item/action_card/action_card_data.dart';
import '../../widgets/message/send_message_dialog/attachment_extra.dart';
import '../job_queue.dart';
import '../sender.dart';

class SendingJob extends JobQueue<Job, List<Job>> {
  SendingJob({
    required super.database,
    required this.sender,
    required this.userId,
    required this.sessionId,
    required this.privateKey,
    required this.signalProtocol,
  });

  final String userId;
  final Sender sender;
  final String sessionId;
  final ed.PrivateKey privateKey;
  late SignalProtocol signalProtocol;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  @override
  String get name => 'SendingJob';

  @override
  Future<void> insertJob(Job job) => database.jobDao.insert(job);

  @override
  Future<List<Job>> fetchJobs() => database.jobDao.sendingJobs().get();

  @override
  bool isValid(List<Job> jobs) => jobs.isNotEmpty;

  @override
  Future<void> run(List<Job> jobs) async {
    for (final job in jobs) {
      try {
        switch (job.action) {
          case kPinMessage:
            await _runPinJob(job);
          case kRecallMessage:
            await _runRecallJob(job);
          case kSendingMessage:
            await _runSendJob(job);
        }
      } catch (e) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  Future<void> _runPinJob(Job job) async {
    final list = await utf8EncodeWithIsolate(job.blazeMessage!);
    final data = await base64EncodeWithIsolate(list);

    final blazeParam = BlazeMessageParam(
      conversationId: job.conversationId,
      messageId: const Uuid().v4(),
      category: MessageCategory.messagePin,
      data: data,
    );
    final blazeMessage = BlazeMessage(
      id: const Uuid().v4(),
      action: kCreateMessage,
      params: blazeParam,
    );
    try {
      final result = await sender.deliver(blazeMessage);
      if (result.success || result.errorCode == badData) {
        await database.jobDao.deleteJobById(job.jobId);
      }
    } catch (e, s) {
      w('Send pin error: $e, stack: $s');
    }
  }

  Future<void> _runRecallJob(Job job) async {
    final list = await utf8EncodeWithIsolate(job.blazeMessage!);
    final data = await base64EncodeWithIsolate(list);

    final blazeParam = BlazeMessageParam(
      conversationId: job.conversationId,
      messageId: const Uuid().v4(),
      category: MessageCategory.messageRecall,
      data: data,
    );
    final blazeMessage = BlazeMessage(
      id: const Uuid().v4(),
      action: kCreateMessage,
      params: blazeParam,
    );
    try {
      final result = await sender.deliver(blazeMessage);
      if (result.success || result.errorCode == badData) {
        await database.jobDao.deleteJobById(job.jobId);
      }
    } catch (e, s) {
      w('Send recall error: $e, stack: $s');
    }
  }

  Future<void> _runSendJob(Job job) async {
    assert(job.blazeMessage != null);
    String messageId;
    String? recipientId;
    var silent = false;
    int? expireIn;
    try {
      final json = (jsonDecode(job.blazeMessage!)) as Map<String, dynamic>;
      messageId = json[JobDao.messageIdKey] as String;
      recipientId = json[JobDao.recipientIdKey] as String?;
      silent = json[JobDao.silentKey] as bool;
      expireIn = json[JobDao.expireInKey] as int?;
    } catch (_) {
      messageId = job.blazeMessage!;
    }

    var message = await database.messageDao
        .sendingMessage(messageId)
        .getSingleOrNull();
    if (message == null) {
      await database.jobDao.deleteJobById(job.jobId);
      return;
    }

    if (message.category.isTranscript) {
      final list = await database.transcriptMessageDao
          .transcriptMessageByTranscriptId(messageId)
          .get();
      final json = list.map((e) {
        if (e.category.isAppCard) {
          try {
            final json = jsonDecode(e.content!) as Map<String, dynamic>;
            final card = AppCardData.fromJson(json);
            if (card.isActionsCard && !card.canShareActions) {
              json.remove('actions');
              e = e.copyWith(content: Value(jsonEncode(json)));
            }
          } catch (error, stacktrace) {
            w('AppCardData.fromJson error: $error, stack: $stacktrace');
          }
        }

        final map = e.toJson(serializer: const UtcValueSerializer());
        map['media_duration'] = int.tryParse(
          map['media_duration'] as String? ?? '',
        );
        map.remove('media_status');
        return map;
      }).toList();
      message = message.copyWith(content: await jsonEncodeWithIsolate(json));
    }

    MessageResult? result;
    var content = message.content;
    String? sentContent;
    if (message.category.isPost || message.category.isText) {
      content = content?.substring(0, min(content.length, kMaxTextLength));
      sentContent = content;
      message = message.copyWith(content: content);
    } else if (message.category.isAttachment && content != null) {
      try {
        final attachment = AttachmentMessage.fromJson(
          (await jsonBase64DecodeWithIsolate(content)) as Map<String, dynamic>,
        );
        final attachmentExtra = AttachmentExtra(
          attachmentId: attachment.attachmentId,
          messageId: messageId,
          createdAt: attachment.createdAt,
        );

        sentContent = await jsonEncodeWithIsolate(attachmentExtra);
      } catch (error) {
        e('Get sentContent error: $error');
      }
    }

    final conversation = await database.conversationDao
        .conversationById(message.conversationId)
        .getSingleOrNull();
    if (conversation == null) {
      e('Conversation not found');
      return;
    }

    try {
      await sender.checkConversationExists(conversation);
    } on MixinApiError catch (apiError) {
      e('Send message error: ${apiError.message} $apiError');
      final error = apiError.error;
      // Maybe get a badData response when create conversation with
      // an invalid user(for example: network user).
      if (error is MixinError && error.code == badData) {
        await database.jobDao.deleteJobById(job.jobId);
        return;
      }
      rethrow;
    }

    if (message.category.isPlain ||
        message.category == MessageCategory.appCard ||
        message.category.isPin) {
      result = await _sendPlainMessage(
        message,
        recipientId: recipientId,
        silent: silent,
        expireIn: expireIn,
      );
    } else if (message.category.isEncrypted) {
      try {
        result = await _sendEncryptedMessage(
          message,
          silent: silent,
          expireIn: expireIn ?? 0,
        );
      } on _NoParticipantSessionKeyException catch (error) {
        e('No participant session key: $error');
        // send plain directly if no participant session key.
        message = message.copyWith(
          category: message.category.replaceAll('ENCRYPTED_', 'PLAIN_'),
        );
        d('category: ${message.category}');
        await database.messageDao.updateCategoryById(
          messageId,
          message.category,
        );
        result = await _sendPlainMessage(
          message,
          recipientId: recipientId,
          silent: silent,
          expireIn: expireIn,
        );
      }
    } else if (message.category.isSignal) {
      result = await _sendSignalMessage(
        message,
        silent: silent,
        expireIn: expireIn ?? 0,
      );
    }

    if (result?.success ?? (result?.errorCode == badData)) {
      if (result?.errorCode == null) {
        await database.messageDao.updateMessageContentAndStatus(
          message.messageId,
          sentContent,
          MessageStatus.sent,
        );
      }
      await database.jobDao.deleteJobById(job.jobId);

      if (conversation.expireIn != null && conversation.expireIn! > 0) {
        await database.expiredMessageDao.insert(
          messageId: messageId,
          expireIn: conversation.expireIn!,
          expireAt:
              DateTime.now().millisecondsSinceEpoch ~/ 1000 +
              conversation.expireIn!,
        );
      }
    }
  }

  BlazeMessage _createBlazeMessage(
    SendingMessage message,
    String data, {
    required int expireIn,
    String? recipientId,
    bool silent = false,
  }) {
    final blazeParam = BlazeMessageParam(
      conversationId: message.conversationId,
      recipientId: recipientId,
      messageId: message.messageId,
      category: message.category,
      data: data,
      quoteMessageId: message.quoteMessageId,
      silent: silent,
      expireIn: expireIn,
    );

    return BlazeMessage(
      id: const Uuid().v4(),
      action: kCreateMessage,
      params: blazeParam,
    );
  }

  Future<List<String>?> getMentionData(String messageId) async {
    final messages = database.mixinDatabase.messages;

    final content =
        await (database.mixinDatabase.selectOnly(messages)
              ..addColumns([messages.content])
              ..where(
                messages.messageId.equals(messageId) &
                    messages.category.isIn([
                      MessageCategory.plainText,
                      MessageCategory.encryptedText,
                      MessageCategory.signalText,
                    ]),
              ))
            .map((row) => row.read(messages.content))
            .getSingleOrNull();

    if (content?.isEmpty ?? true) return null;
    final ids = mentionNumberRegExp.allMatches(content!).map((e) => e[1]!);
    if (ids.isEmpty) return null;
    return database.userDao.findMultiUserIdsByIdentityNumbers(ids);
  }

  Future<BlazeMessage> encryptNormalMessage(
    SendingMessage message, {
    bool silent = false,
    int expireIn = 0,
  }) async {
    var m = message;
    if (message.category.isLive && message.content != null) {
      final list = await utf8EncodeWithIsolate(message.content!);
      m = message.copyWith(content: await base64EncodeWithIsolate(list));
    }
    return signalProtocol.encryptGroupMessage(
      m,
      await getMentionData(m.messageId),
      silent: silent,
      expireIn: expireIn,
    );
  }

  Future<MessageResult> _sendPlainMessage(
    SendingMessage message, {
    String? recipientId,
    bool silent = false,
    int? expireIn,
  }) async {
    var content = message.content;
    if (message.category == MessageCategory.appCard ||
        message.category.isPost ||
        message.category.isTranscript ||
        message.category.isText ||
        message.category.isLive ||
        message.category.isLocation) {
      final list = await utf8EncodeWithIsolate(content!);
      content = await base64EncodeWithIsolate(list);
    }
    final blazeMessage = _createBlazeMessage(
      message,
      content!,
      recipientId: recipientId,
      silent: silent,
      expireIn: expireIn ?? 0,
    );
    return sender.deliver(blazeMessage);
  }

  Future<MessageResult> _sendEncryptedMessage(
    SendingMessage message, {
    required int expireIn,
    bool silent = false,
  }) async {
    var participantSessionKey = await database.participantSessionDao
        .participantSessionKeyWithoutSelf(message.conversationId, userId)
        .getSingleOrNull();

    if (participantSessionKey == null ||
        participantSessionKey.publicKey.isNullOrBlank()) {
      await sender.syncConversation(message.conversationId);
      participantSessionKey = await database.participantSessionDao
          .participantSessionKeyWithoutSelf(message.conversationId, userId)
          .getSingleOrNull();
    }

    // Workaround no session key, can't encrypt message
    if (participantSessionKey == null ||
        participantSessionKey.publicKey.isNullOrBlank()) {
      throw _NoParticipantSessionKeyException(message.conversationId, userId);
    }

    final otherSessionKey = await database.participantSessionDao
        .otherParticipantSessionKey(
          message.conversationId,
          userId,
          sessionId,
        )
        .getSingleOrNull();

    final plaintext =
        message.category.isAttachment ||
            message.category.isSticker ||
            message.category.isContact ||
            message.category.isLive
        ? base64Decode(message.content!)
        : await utf8EncodeWithIsolate(message.content!);

    final content = _encryptedProtocol.encryptMessage(
      privateKey,
      plaintext,
      base64Decode(base64.normalize(participantSessionKey.publicKey!)),
      participantSessionKey.sessionId,
      otherSessionKey?.publicKey == null
          ? null
          : base64Decode(base64.normalize(otherSessionKey!.publicKey!)),
      otherSessionKey?.sessionId,
    );

    final blazeMessage = _createBlazeMessage(
      message,
      await base64EncodeWithIsolate(content),
      silent: silent,
      expireIn: expireIn,
    );
    return sender.deliver(blazeMessage);
  }

  Future<MessageResult?> _sendSignalMessage(
    SendingMessage message, {
    required int expireIn,
    bool silent = false,
  }) async {
    MessageResult? result;
    if (message.resendStatus != null) {
      if (message.resendStatus == 1) {
        final check = await sender.checkSignalSession(
          message.resendUserId!,
          message.resendSessionId!,
        );
        if (check) {
          final encrypted = await signalProtocol.encryptSessionMessage(
            message,
            message.resendUserId!,
            resendMessageId: message.messageId,
            sessionId: message.resendSessionId,
            mentionData: await getMentionData(message.messageId),
            silent: silent,
            expireIn: expireIn,
          );
          result = await sender.deliver(encrypted);
          if (result.success || result.errorCode == badData) {
            await database.resendSessionMessageDao
                .deleteResendSessionMessageById(message.messageId);
          }
        }
      }
      return result;
    }
    if (!await signalProtocol.isExistSenderKey(
      message.conversationId,
      message.userId,
    )) {
      await sender.checkConversation(message.conversationId);
    }
    await sender.checkSessionSenderKey(message.conversationId);
    result = await sender.deliver(
      await encryptNormalMessage(message, silent: silent, expireIn: expireIn),
    );
    if (!result.success && result.retry) {
      return _sendSignalMessage(message, silent: silent, expireIn: expireIn);
    }
    return result;
  }
}

class _NoParticipantSessionKeyException implements Exception {
  _NoParticipantSessionKeyException(this.conversationId, this.userId);

  final String conversationId;
  final String userId;

  @override
  String toString() =>
      'No participant session key for conversation: $conversationId, user: $userId';
}
