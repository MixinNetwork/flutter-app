import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:equatable/equatable.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_message_param.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/converter/utc_value_serializer.dart';
import '../db/dao/job_dao.dart';
import '../db/dao/sticker_dao.dart';
import '../db/database.dart';
import '../db/extension/message.dart';
import '../db/mixin_database.dart' as db;
import '../db/mixin_database.dart';
import '../enum/message_category.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/mixin_api_client.dart';
import '../utils/reg_exp_utils.dart';
import 'decrypt_message.dart';
import 'isolate_event.dart';
import 'sender.dart';

class IsolateInitParams {
  IsolateInitParams({
    required this.sendPort,
    required this.identityNumber,
    required this.userId,
    required this.sessionId,
    required this.privateKey,
    required this.mixinDocumentDirectory,
    required this.primarySessionId,
    required this.packageInfo,
  });

  final SendPort sendPort;
  final String identityNumber;
  final String userId;
  final String sessionId;
  final String privateKey;
  final String mixinDocumentDirectory;
  final String? primarySessionId;
  final PackageInfo packageInfo;
}

Future<void> startMessageProcessIsolate(IsolateInitParams params) async {
  EquatableConfig.stringify = true;
  mixinDocumentsDirectory = Directory(params.mixinDocumentDirectory);
  final isolateChannel =
      IsolateChannel<IsolateEvent>.connectSend(params.sendPort);
  final runner = _MessageProcessRunner(
    identityNumber: params.identityNumber,
    userId: params.userId,
    sessionId: params.sessionId,
    privateKeyStr: params.privateKey,
    primarySessionId: params.primarySessionId,
    eventSink: isolateChannel.sink,
    sendPort: params.sendPort,
  );
  isolateChannel.stream.listen((event) {
    assert(event is MainIsolateEvent, 'event is not MainIsolateEvent');
    if (event is! MainIsolateEvent) {
      return;
    }
    try {
      runner.onEvent(event);
    } catch (error, stacktrace) {
      e('error: $error, stacktrace: $stacktrace');
    }
  });
  await runner.init(params);
  runner._start();
  isolateChannel.sink.add(WorkerIsolateEventType.onIsolateReady.toEvent());
}

final Map<String, MessageStatus> pendingMessageStatusMap = {};

class _MessageProcessRunner {
  _MessageProcessRunner({
    required this.identityNumber,
    required this.userId,
    required this.sessionId,
    required this.privateKeyStr,
    required this.primarySessionId,
    required this.eventSink,
    required this.sendPort,
  }) : privateKey = PrivateKey(base64Decode(privateKeyStr));

  final String identityNumber;
  final String userId;
  final String sessionId;
  final String privateKeyStr;
  final PrivateKey privateKey;
  final String? primarySessionId;
  final SendPort sendPort;

  final Sink<IsolateEvent> eventSink;

  late DecryptMessage _decryptMessage;

  late Client client;
  late Database database;
  late Blaze blaze;
  late Sender _sender;
  late SignalProtocol signalProtocol;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  final jobSubscribers = <StreamSubscription>[];

  Timer? _nextExpiredMessageRunner;

  Future<void> init(IsolateInitParams initParams) async {
    database = Database(await connectToDatabase(identityNumber, readCount: 2));
    jobSubscribers.add(
      database.mixinDatabase.eventBus.stream.listen((event) {
        _sendEventToMainIsolate(WorkerIsolateEventType.onDbEvent, event);
      }),
    );

    client = createClient(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKeyStr,
      interceptors: [
        InterceptorsWrapper(
          onError: (
            DioError e,
            ErrorInterceptorHandler handler,
          ) async {
            _sendEventToMainIsolate(
                WorkerIsolateEventType.onApiRequestedError, e);
            handler.next(e);
          },
        ),
      ],
    );

    blaze = Blaze(
      userId,
      sessionId,
      privateKeyStr,
      database,
      client,
      initParams.packageInfo,
    );

    blaze.connectedStateStream.listen((event) {
      _sendEventToMainIsolate(
          WorkerIsolateEventType.onBlazeConnectStateChanged, event);
    });

    signalProtocol = SignalProtocol(userId);
    await signalProtocol.init();

    _sender = Sender(
      signalProtocol,
      blaze,
      client,
      sessionId,
      userId,
      database,
    );

    _decryptMessage = DecryptMessage(
      userId,
      database,
      signalProtocol,
      _sender,
      client,
      sessionId,
      privateKey,
      _sendEventToMainIsolate,
      identityNumber,
    );
  }

  void _start() {
    blaze.connect();

    if (primarySessionId != null) {
      jobSubscribers.add(database.jobDao
          .watchHasSessionAckJobs()
          .asyncDropListen((_) => _runSessionAckJob()));
    }

    jobSubscribers
      ..add(Rx.merge([
        // runFloodJob when socket connected.
        blaze.connectedStateStream
            .where((state) => state == ConnectedState.connected),
        database.mixinDatabase.tableUpdates(
          TableUpdateQuery.onTable(database.mixinDatabase.floodMessages),
        )
      ]).asyncDropListen((_) async {
        try {
          await _runProcessFloodJob();
        } catch (error, stacktrace) {
          e('runProcessFloodJob error: $error, stacktrace: $stacktrace');
        }
      }))
      ..add(database.jobDao
          .watchHasAckJobs()
          .asyncDropListen((_) => _runAckJob()))
      ..add(database.jobDao.watchHasSendingJobs().asyncDropListen((_) async {
        while (true) {
          final jobs = await database.jobDao.sendingJobs().get();
          if (jobs.isEmpty) break;
          await Future.forEach(jobs, (db.Job job) async {
            try {
              switch (job.action) {
                case kSendingMessage:
                  await _runSendJob([job]);
                  break;
                case kPinMessage:
                  await _runPinJob([job]);
                  break;
                case kRecallMessage:
                  await _runRecallJob([job]);
                  break;
              }
            } catch (error) {
              e('send job error: $error');
            }
            return null;
          });
        }
      }))
      ..add(database.jobDao
          .watchHasUpdateAssetJobs()
          .asyncDropListen((_) => _runUpdateAssetJob()))
      ..add(database.jobDao
          .watchHasUpdateStickerJobs()
          .asyncDropListen((_) => _runUpdateStickerJob()))
      ..add(database.mixinDatabase
          .tableUpdates(
            TableUpdateQuery.onTable(database.mixinDatabase.expiredMessages),
          )
          .asyncDropListen((event) => _scheduleExpiredJob()));
  }

  void _sendEventToMainIsolate(WorkerIsolateEventType event,
      [dynamic argument]) {
    eventSink.add(event.toEvent(argument));
  }

  Future<void> _scheduleExpiredJob() async {
    d('_scheduleExpiredJob');
    while (true) {
      final messages =
          await database.expiredMessageDao.getCurrentExpiredMessages();
      if (messages.isEmpty) {
        break;
      }
      for (final em in messages) {
        // cancel attachment download.
        final message =
            await database.messageDao.findMessageByMessageId(em.messageId);
        if (message == null) {
          e('message is null, messageId: ${em.messageId} ${em.expireAt}');
          continue;
        }
        await database.messageDao.deleteMessage(em.messageId);
        if (message.category.isAttachment || message.category.isTranscript) {
          _sendEventToMainIsolate(
            WorkerIsolateEventType.requestDownloadAttachment,
            AttachmentDeleteRequest(message: message),
          );
        }
      }
    }

    final firstExpiredMessage =
        await database.mixinDatabase.getFirstExpiredMessage().getSingleOrNull();
    if (firstExpiredMessage == null) {
      _nextExpiredMessageRunner?.cancel();
      _nextExpiredMessageRunner = null;
      return;
    }
    _nextExpiredMessageRunner?.cancel();
    _nextExpiredMessageRunner = Timer(
      Duration(
          seconds: firstExpiredMessage.expireAt! -
              DateTime.now().millisecondsSinceEpoch ~/ 1000),
      _scheduleExpiredJob,
    );
  }

  Future<void> _runProcessFloodJob() async {
    var first = true;
    while (true) {
      final floodMessages =
          await database.floodMessageDao.findFloodMessage().get();
      if (floodMessages.isEmpty) {
        i('_runProcessFloodJob: no flood message: $first');
        return;
      }
      first = false;
      final stopwatch = Stopwatch()..start();
      for (final message in floodMessages) {
        await _decryptMessage.process(message);
      }
      i('processMessage(${floodMessages.length}): ${stopwatch.elapsedMilliseconds}');
    }
  }

  Future<void> _runAckJob() async {
    while (true) {
      final jobs = await database.jobDao.ackJobs().get();
      if (jobs.isEmpty) break;

      final ack = jobs.map(
        (e) {
          final map = jsonDecode(e.blazeMessage!) as Map<String, dynamic>;
          return BlazeAckMessage.fromJson(map);
        },
      );

      final jobIds = jobs.map((e) => e.jobId).toList();
      try {
        //  await client.messageApi.acknowledgements(ack);
        final rsp = await client.dio.post('/acknowledgements', data: ack);
        i('acknowledgements ids: ${ack.map((e) => e.messageId).toList()}, request id: ${rsp.headers['x-request-id']}');
        await database.jobDao.deleteJobs(jobIds);
      } catch (e, s) {
        w('Send ack error: $e, stack: $s');
      }
    }
  }

  Future<void> _runUpdateAssetJob() async {
    while (true) {
      final jobs = await database.jobDao.updateAssetJobs().get();
      if (jobs.isEmpty) return;

      await Future.wait(jobs.map((db.Job job) async {
        try {
          final a =
              (await client.assetApi.getAssetById(job.blazeMessage!)).data;
          await database.assetDao.insertSdkAsset(a);
          await database.jobDao.deleteJobById(job.jobId);
        } catch (e, s) {
          w('Update asset job error: $e, stack: $s');
        }
      }));
    }
  }

  Future<void> _runUpdateStickerJob() async {
    while (true) {
      final jobs = await database.jobDao.updateStickerJobs().get();
      if (jobs.isEmpty) return;

      await Future.wait(jobs.map((db.Job job) async {
        try {
          final stickerId = job.blazeMessage;
          if (stickerId != null) {
            final sticker =
                (await client.accountApi.getStickerById(stickerId)).data;
            await database.stickerDao.insert(sticker.asStickersCompanion);
          }
          await database.jobDao.deleteJobById(job.jobId);
        } catch (e, s) {
          w('Update sticker job error: $e, stack: $s');
        }
      }));
    }
  }

  Future<void> _runSendJob(List<db.Job> jobs) async {
    Future<void> send(db.Job job) async {
      assert(job.blazeMessage != null);
      String messageId;
      String? recipientId;
      var silent = false;
      int? expireIn;
      try {
        final json = jsonDecode(job.blazeMessage!) as Map<String, dynamic>;
        messageId = json[JobDao.messageIdKey] as String;
        recipientId = json[JobDao.recipientIdKey] as String?;
        silent = json[JobDao.silentKey] as bool;
        expireIn = json[JobDao.expireInKey] as int?;
      } catch (_) {
        messageId = job.blazeMessage!;
      }

      var message = await database.messageDao.sendingMessage(messageId);
      if (message == null) {
        await database.jobDao.deleteJobById(job.jobId);
        return;
      }

      if (message.category.isTranscript) {
        final list = await database.transcriptMessageDao
            .transcriptMessageByTranscriptId(messageId)
            .get();
        final json = list.map((e) {
          final map = e.toJson(serializer: const UtcValueSerializer());
          map['media_duration'] =
              int.tryParse(map['media_duration'] as String? ?? '');
          map.remove('media_status');

          return map;
        }).toList();
        message = message.copyWith(content: jsonEncode(json));
      }

      MessageResult? result;
      var content = message.content;
      String? lengthLimitedContent;
      if (message.category.isPost || message.category.isText) {
        content = content?.substring(0, min(content.length, kMaxTextLength));
        lengthLimitedContent = content;
      }

      final conversation = await database.conversationDao
          .conversationById(message.conversationId)
          .getSingleOrNull();
      if (conversation == null) {
        e('Conversation not found');
        return;
      }

      try {
        await _sender.checkConversationExists(conversation);
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
        if (message.category == MessageCategory.appCard ||
            message.category.isPost ||
            message.category.isTranscript ||
            message.category.isText ||
            message.category.isLive ||
            message.category.isLocation) {
          final list = utf8.encode(content!);
          content = base64Encode(list);
        }
        final blazeMessage = _createBlazeMessage(
          message,
          content!,
          recipientId: recipientId,
          silent: silent,
          expireIn: expireIn ?? 0,
        );
        result = await _sender.deliver(blazeMessage);
      } else if (message.category.isEncrypted) {
        final participantSessionKey = await database.participantSessionDao
            .getParticipantSessionKeyWithoutSelf(
                message.conversationId, userId);
        final otherSessionKey = await database.participantSessionDao
            .getOtherParticipantSessionKey(
                message.conversationId, userId, sessionId);
        if (otherSessionKey == null ||
            otherSessionKey.publicKey == null ||
            participantSessionKey == null ||
            participantSessionKey.publicKey == null) {
          await _sender.checkConversation(message.conversationId);
          return;
        }
        final plaintext = message.category.isAttachment ||
                message.category.isSticker ||
                message.category.isContact ||
                message.category.isLive
            ? base64Decode(message.content!)
            : utf8.encode(message.content!);
        final content = _encryptedProtocol.encryptMessage(
            privateKey,
            plaintext,
            base64Decode(base64.normalize(participantSessionKey.publicKey!)),
            participantSessionKey.sessionId,
            base64Decode(base64.normalize(otherSessionKey.publicKey!)),
            otherSessionKey.sessionId);

        final blazeMessage = _createBlazeMessage(
          message,
          base64Encode(content),
          silent: silent,
          expireIn: expireIn ?? 0,
        );
        result = await _sender.deliver(blazeMessage);
      } else if (message.category.isSignal) {
        result = await _sendSignalMessage(
          message,
          silent: silent,
          expireIn: expireIn ?? 0,
        );
      }

      if (result?.success ?? false || result?.errorCode == badData) {
        if (result?.errorCode == null) {
          await database.messageDao.updateMessageContentAndStatus(
            message.messageId,
            lengthLimitedContent,
            MessageStatus.sent,
          );
        }
        await database.jobDao.deleteJobById(job.jobId);

        if (conversation.expireIn != null && conversation.expireIn! > 0) {
          await database.expiredMessageDao.insert(
            messageId: messageId,
            expireIn: conversation.expireIn!,
            expireAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 +
                conversation.expireIn!,
          );
        }
      }
    }

    await Future.forEach(jobs, (db.Job job) async {
      try {
        await send(job);
      } catch (e, s) {
        w('Send job error: $e, stack: $s');
      }
    });
  }

  Future<void> _runRecallJob(List<db.Job> jobs) async {
    await Future.forEach(jobs, (db.Job e) async {
      final list = utf8.encode(e.blazeMessage!);
      final data = base64Encode(list);

      final blazeParam = BlazeMessageParam(
        conversationId: e.conversationId,
        messageId: const Uuid().v4(),
        category: MessageCategory.messageRecall,
        data: data,
      );
      final blazeMessage = BlazeMessage(
          id: const Uuid().v4(), action: kCreateMessage, params: blazeParam);
      try {
        final result = await _sender.deliver(blazeMessage);
        if (result.success || result.errorCode == badData) {
          await database.jobDao.deleteJobById(e.jobId);
        }
      } catch (e, s) {
        w('Send recall error: $e, stack: $s');
      }
    });
  }

  Future<void> _runPinJob(List<db.Job> jobs) async {
    await Future.forEach(jobs, (db.Job e) async {
      final list = utf8.encode(e.blazeMessage!);
      final data = base64Encode(list);

      final blazeParam = BlazeMessageParam(
        conversationId: e.conversationId,
        messageId: const Uuid().v4(),
        category: MessageCategory.messagePin,
        data: data,
      );
      final blazeMessage = BlazeMessage(
          id: const Uuid().v4(), action: kCreateMessage, params: blazeParam);
      try {
        final result = await _sender.deliver(blazeMessage);
        if (result.success || result.errorCode == badData) {
          await database.jobDao.deleteJobById(e.jobId);
        }
      } catch (e, s) {
        w('Send pin error: $e, stack: $s');
      }
    });
  }

  Future<MessageResult?> _sendSignalMessage(
    db.SendingMessage message, {
    bool silent = false,
    required int expireIn,
  }) async {
    MessageResult? result;
    if (message.resendStatus != null) {
      if (message.resendStatus == 1) {
        final check = await _sender.checkSignalSession(
            message.resendUserId!, message.resendSessionId!);
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
          result = await _sender.deliver(encrypted);
          if (result.success || result.errorCode == badData) {
            await database.resendSessionMessageDao
                .deleteResendSessionMessageById(message.messageId);
          }
        }
      }
      return result;
    }
    if (!await signalProtocol.isExistSenderKey(
        message.conversationId, message.userId)) {
      await _sender.checkConversation(message.conversationId);
    }
    await _sender.checkSessionSenderKey(message.conversationId);
    result = await _sender.deliver(await encryptNormalMessage(
      message,
      silent: silent,
      expireIn: expireIn,
    ));
    if (!result.success && result.retry) {
      return _sendSignalMessage(
        message,
        silent: silent,
        expireIn: expireIn,
      );
    }
    return result;
  }

  Future<BlazeMessage> encryptNormalMessage(
    db.SendingMessage message, {
    bool silent = false,
    int expireIn = 0,
  }) async {
    var m = message;
    if (message.category.isLive && message.content != null) {
      final list = utf8.encode(message.content!);
      m = message.copyWith(content: base64Encode(list));
    }
    return signalProtocol.encryptGroupMessage(
      m,
      await getMentionData(m.messageId),
      silent: silent,
      expireIn: expireIn,
    );
  }

  BlazeMessage _createBlazeMessage(
    db.SendingMessage message,
    String data, {
    String? recipientId,
    bool silent = false,
    required int expireIn,
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

    final equals = messages.messageId.equals(messageId);

    final content = await (database.mixinDatabase.selectOnly(messages)
          ..addColumns([messages.content])
          ..where(equals &
              messages.category.isIn([
                MessageCategory.plainText,
                MessageCategory.encryptedText,
                MessageCategory.signalText
              ])))
        .map((row) => row.read(messages.content))
        .getSingleOrNull();

    if (content?.isEmpty ?? true) return null;
    final ids = mentionNumberRegExp.allMatches(content!).map((e) => e[1]!);
    if (ids.isEmpty) return null;
    return database.userDao.findMultiUserIdsByIdentityNumbers(ids);
  }

  Future<void> _runSessionAckJob() async {
    while (true) {
      final jobs = await database.jobDao.sessionAckJobs().get();
      if (jobs.isEmpty) return;

      final conversationId =
          await database.participantDao.findJoinedConversationId(userId);
      if (conversationId == null) return;

      final ack = jobs.map(
        (e) {
          final map = jsonDecode(e.blazeMessage!) as Map<String, dynamic>;
          return BlazeAckMessage.fromJson(map);
        },
      ).toList();
      final jobIds = jobs.map((e) => e.jobId).toList();
      final plainText = PlainJsonMessage(
          kAcknowledgeMessageReceipts, null, null, null, null, ack);
      final encode = base64Encode(utf8.encode(jsonEncode(plainText)));
      // TODO check if safety to use a primary session.
      // final primarySessionId = AccountKeyValue.instance.primarySessionId;
      final bm = createParamBlazeMessage(createPlainJsonParam(
          conversationId, userId, encode,
          sessionId: primarySessionId));
      try {
        final result = await _sender.deliver(bm);
        if (result.success || result.errorCode == badData) {
          await database.jobDao.deleteJobs(jobIds);
        }
      } catch (e, s) {
        w('Send session ack error: $e, stack: $s');
      }
    }
  }

  void onEvent(MainIsolateEvent event) {
    switch (event.type) {
      case MainIsolateEventType.updateSelectedConversation:
        final conversationId = event.argument as String?;
        _decryptMessage.conversationId = conversationId;
        break;
      case MainIsolateEventType.disconnectBlazeWithTime:
        blaze.waitSyncTime();
        break;
      case MainIsolateEventType.reconnectBlaze:
        blaze.reconnect();
        break;
      case MainIsolateEventType.exit:
        dispose();
        Isolate.exit();
    }
  }

  void dispose() {
    blaze.dispose();
    database.dispose();
    jobSubscribers.forEach((subscription) => subscription.cancel());
  }
}
