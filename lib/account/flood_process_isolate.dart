import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_param.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/converter/utc_value_serializer.dart';
import '../db/dao/job_dao.dart';
import '../db/database.dart';
import '../db/extension/message.dart';
import '../db/mixin_database.dart' as db;
import '../db/mixin_database.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/reg_exp_utils.dart';
import '../workers/decrypt_message.dart';
import '../workers/sender.dart';

class DecryptMessageInitParams {
  DecryptMessageInitParams({
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

Future<void> startFloodProcessIsolate(DecryptMessageInitParams params) async {
  mixinDocumentsDirectory = Directory(params.mixinDocumentDirectory);
  final isolateChannel = IsolateChannel.connectSend(params.sendPort);
  final floodProcessRunner = FloodMessageProcessRunner(
    identityNumber: params.identityNumber,
    userId: params.userId,
    sessionId: params.sessionId,
    privateKeyStr: params.privateKey,
    primarySessionId: params.primarySessionId,
  );
  isolateChannel.stream.listen((event) {});
  await floodProcessRunner.init(params);
  floodProcessRunner._start();
}

class FloodMessageProcessRunner {
  FloodMessageProcessRunner({
    required this.identityNumber,
    required this.userId,
    required this.sessionId,
    required this.privateKeyStr,
    required this.primarySessionId,
  }) : privateKey = PrivateKey(base64Decode(privateKeyStr));

  final String identityNumber;
  final String userId;
  final String sessionId;
  final String privateKeyStr;
  final PrivateKey privateKey;
  final String? primarySessionId;

  late DecryptMessage _decryptMessage;

  late Client client;
  late Database database;
  late Blaze blaze;
  late Sender _sender;
  late SignalProtocol signalProtocol;

  late AttachmentUtil attachmentUtil;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  final jobSubscribers = <StreamSubscription>[];

  Future<void> init(DecryptMessageInitParams initParams) async {
    database = Database(await connectToDatabase(identityNumber));

    final tenSecond = const Duration(seconds: 10).inMilliseconds;
    client = Client(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKeyStr,
      scp: scp,
      dioOptions: BaseOptions(
        connectTimeout: tenSecond,
        receiveTimeout: tenSecond,
        sendTimeout: tenSecond,
      ),
      jsonDecodeCallback: jsonDecode,
      interceptors: [
        InterceptorsWrapper(
          onError: (
            DioError e,
            ErrorInterceptorHandler handler,
          ) async {
            // TODO send to main isolate.
            handler.next(e);
          },
        ),
      ],
      httpLogLevel: HttpLogLevel.none,
    );

    attachmentUtil = AttachmentUtil.init(
      client,
      database.messageDao,
      database.transcriptMessageDao,
      identityNumber,
    );

    blaze = Blaze(
      userId,
      sessionId,
      privateKeyStr,
      database,
      client,
      initParams.packageInfo,
    );

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
      attachmentUtil,
    );
  }

  void _start() {
    blaze.connect();

    if (primarySessionId != null) {
      jobSubscribers.add(database.jobDao
          .watchHasSessionAckJobs()
          .asyncListen((_) => _runSessionAckJob()));
    }

    jobSubscribers
      ..add(Rx.merge([
        // runFloodJob when socket connected.
        blaze.connectedStateStream
            .where((state) => state == ConnectedState.connected),
        database.mixinDatabase.tableUpdates(
          TableUpdateQuery.onTable(database.mixinDatabase.floodMessages),
        )
      ]).asyncListen((_) => _runProcessFloodJob()))
      ..add(database.jobDao.watchHasAckJobs().asyncListen((_) => _runAckJob()))
      ..add(database.jobDao.watchHasSendingJobs().asyncListen((_) async {
        while (true) {
          final jobs = await database.jobDao.sendingJobs().get();
          if (jobs.isEmpty) break;
          await Future.forEach(jobs, (db.Job job) async {
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
            return null;
          });
        }
      }))
      ..add(database.jobDao
          .watchHasUpdateAssetJobs()
          .asyncListen((_) => _runUpdateAssetJob()));
  }

  Future<void> _runProcessFloodJob() async {
    i('_runProcessFloodJob');
    final floodMessages =
        await database.floodMessageDao.findFloodMessage().get();
    if (floodMessages.isEmpty) {
      return;
    }
    Stopwatch? stopwatch;
    if (!kReleaseMode) {
      stopwatch = Stopwatch()..start();
    }
    for (final message in floodMessages) {
      await _decryptMessage.process(message);
    }
    if (stopwatch != null) {
      d('process execution time ${floodMessages.length} : ${stopwatch.elapsedMilliseconds}');
    }
    await _runProcessFloodJob();
  }

  Future<void> _runAckJob() async {
    final jobs = await database.jobDao.ackJobs().get();
    if (jobs.isEmpty) return;

    final ack = await Future.wait(
      jobs.map(
        (e) async {
          final map = await jsonDecodeWithIsolate(e.blazeMessage!)
              as Map<String, dynamic>;
          return BlazeAckMessage(
            messageId: map['message_id'] as String,
            status: map['status'] as String,
          );
        },
      ),
    );

    final jobIds = jobs.map((e) => e.jobId).toList();
    try {
      await client.messageApi.acknowledgements(ack);
      await database.jobDao.deleteJobs(jobIds);
    } catch (e, s) {
      w('Send ack error: $e, stack: $s');
    }

    await _runAckJob();
  }

  Future<void> _runUpdateAssetJob() async {
    final jobs = await database.jobDao.updateAssetJobs().get();
    if (jobs.isEmpty) return;

    await Future.forEach(jobs, (db.Job job) async {
      try {
        final a = (await client.assetApi.getAssetById(job.blazeMessage!)).data;
        await database.assetDao.insertSdkAsset(a);
        await database.jobDao.deleteJobById(job.jobId);
      } catch (e, s) {
        w('Update asset job error: $e, stack: $s');
      }
    });

    await _runUpdateAssetJob();
  }

  Future<void> _runSendJob(List<db.Job> jobs) async {
    Future<void> send(db.Job job) async {
      assert(job.blazeMessage != null);
      String messageId;
      String? recipientId;
      var silent = false;
      try {
        final json = await jsonDecodeWithIsolate(job.blazeMessage!)
            as Map<String, dynamic>;
        messageId = json[JobDao.messageIdKey] as String;
        recipientId = json[JobDao.recipientIdKey] as String?;
        silent = json[JobDao.silentKey] as bool;
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
        final json = list
            .map((e) => e.toJson(serializer: const UtcValueSerializer())
              ..remove('media_status'))
            .toList();
        message = message.copyWith(content: await jsonEncodeWithIsolate(json));
      }

      MessageResult? result;
      var content = message.content;

      if (message.category.isPlain ||
          message.category == MessageCategory.appCard ||
          message.category.isPin) {
        if (message.category == MessageCategory.appCard ||
            message.category.isPost ||
            message.category.isText) {
          final list = await utf8EncodeWithIsolate(content!);
          content = await base64EncodeWithIsolate(list);
        }
        final blazeMessage = _createBlazeMessage(
          message,
          content!,
          recipientId: recipientId,
          silent: silent,
        );
        result = await _sender.deliver(blazeMessage);
      } else if (message.category.isEncrypted) {
        final conversation = await database.conversationDao
            .conversationById(message.conversationId)
            .getSingleOrNull();
        if (conversation == null) return;
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
        final List<int> plaintext;
        if (message.category.isAttachment ||
            message.category.isSticker ||
            message.category.isContact ||
            message.category.isLive) {
          plaintext = await base64DecodeWithIsolate(message.content!);
        } else {
          plaintext = await utf8EncodeWithIsolate(message.content!);
        }
        final content = _encryptedProtocol.encryptMessage(
            privateKey,
            plaintext,
            await base64DecodeWithIsolate(
                base64.normalize(participantSessionKey.publicKey!)),
            participantSessionKey.sessionId,
            await base64DecodeWithIsolate(
                base64.normalize(otherSessionKey.publicKey!)),
            otherSessionKey.sessionId);

        final blazeMessage = _createBlazeMessage(
          message,
          await base64EncodeWithIsolate(content),
          silent: silent,
        );
        result = await _sender.deliver(blazeMessage);
      } else if (message.category.isSignal) {
        result = await _sendSignalMessage(message, silent: silent);
      } else {}

      if (result?.success ?? false) {
        await database.messageDao
            .updateMessageStatusById(message.messageId, MessageStatus.sent);
        await database.jobDao.deleteJobById(job.jobId);
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
      final list = await utf8EncodeWithIsolate(e.blazeMessage!);
      final data = await base64EncodeWithIsolate(list);

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
        if (result.success) {
          await database.jobDao.deleteJobById(e.jobId);
        }
      } catch (e, s) {
        w('Send recall error: $e, stack: $s');
      }
    });
  }

  Future<void> _runPinJob(List<db.Job> jobs) async {
    await Future.forEach(jobs, (db.Job e) async {
      final list = await utf8EncodeWithIsolate(e.blazeMessage!);
      final data = await base64EncodeWithIsolate(list);

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
        if (result.success) {
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
          );
          result = await _sender.deliver(encrypted);
          if (result.success) {
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
    ));
    if (result.success == false && result.retry == true) {
      return _sendSignalMessage(
        message,
        silent: silent,
      );
    }
    return result;
  }

  Future<BlazeMessage> encryptNormalMessage(
    db.SendingMessage message, {
    bool silent = false,
  }) async =>
      signalProtocol.encryptGroupMessage(
        message,
        await getMentionData(message.messageId),
        silent: silent,
      );

  BlazeMessage _createBlazeMessage(
    db.SendingMessage message,
    String data, {
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
    final jobs = await database.jobDao.sessionAckJobs().get();
    if (jobs.isEmpty) return;

    final conversationId =
        await database.participantDao.findJoinedConversationId(userId);
    if (conversationId == null) {
      return;
    }
    final ack = await Future.wait(
      jobs.map(
        (e) async {
          final map = await jsonDecodeWithIsolate(e.blazeMessage!)
              as Map<String, dynamic>;
          return BlazeAckMessage(
            messageId: map['message_id'] as String,
            status: map['status'] as String,
          );
        },
      ),
    );
    final jobIds = jobs.map((e) => e.jobId).toList();
    final plainText = PlainJsonMessage(
        kAcknowledgeMessageReceipts, null, null, null, null, ack);
    final encode = await base64EncodeWithIsolate(
        await utf8EncodeWithIsolate(await jsonEncodeWithIsolate(plainText)));
    // TODO check if safety to use a primary session.
    // final primarySessionId = AccountKeyValue.instance.primarySessionId;
    final bm = createParamBlazeMessage(createPlainJsonParam(
        conversationId, userId, encode,
        sessionId: primarySessionId));
    try {
      final result = await _sender.deliver(bm);
      if (result.success) {
        await database.jobDao.deleteJobs(jobIds);
      }
    } catch (e, s) {
      w('Send session ack error: $e, stack: $s');
    }

    await _runSessionAckJob();
  }

  void dispose() {
    jobSubscribers.forEach((subscription) => subscription.cancel());
  }
}
