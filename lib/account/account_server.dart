import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_param.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/pin_message_minimal.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/privacy_key_value.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../crypto/uuid/uuid.dart';
import '../db/converter/utc_value_serializer.dart';
import '../db/dao/job_dao.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart' as db;
import '../enum/encrypt_category.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/app_lifecycle.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/hive_key_values.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/webview.dart';
import '../workers/decrypt_message.dart';
import '../workers/sender.dart';
import 'account_key_value.dart';
import 'send_message_helper.dart';

class AccountServer {
  AccountServer(this.multiAuthCubit);

  static String? sid;

  set language(String language) =>
      client.dio.options.headers['Accept-Language'] = language;

  final MultiAuthCubit multiAuthCubit;
  Timer? checkSignalKeyTimer;

  Future<void> initServer(
    String userId,
    String sessionId,
    String identityNumber,
    String privateKey,
  ) async {
    if (sid == sessionId) return;
    sid = sessionId;

    this.userId = userId;
    this.sessionId = sessionId;
    this.identityNumber = identityNumber;
    this.privateKey = PrivateKey(base64Decode(privateKey));

    final tenSecond = const Duration(seconds: 10).inMilliseconds;
    client = Client(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
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
            if (e is MixinApiError &&
                (e.error as MixinError).code == authentication) {
              final serverTime = int.tryParse(
                  e.response?.headers.value('x-server-time') ?? '');
              if (serverTime != null) {
                final time =
                    DateTime.fromMicrosecondsSinceEpoch(serverTime ~/ 1000);
                final difference = time.difference(DateTime.now());
                if (difference.inMinutes.abs() > 5) {
                  blaze.waitSyncTime();
                  handler.next(e);
                  return;
                }
              }
              await signOutAndClear();
              multiAuthCubit.signOut();
            }
            handler.next(e);
          },
        ),
      ],
      httpLogLevel: HttpLogLevel.none,
    );
    await _initDatabase(privateKey, multiAuthCubit);

    checkSignalKeyTimer = Timer.periodic(const Duration(days: 1), (timer) {
      i('refreshSignalKeys periodic');
      checkSignalKey(client);
    });

    try {
      await checkSignalKeys();
    } on InvalidKeyException catch (e, s) {
      w('$e, $s');
      await signOutAndClear();
      multiAuthCubit.signOut();
      return;
    }

    start();

    appActiveListener.addListener(onActive);
  }

  void onActive() {
    if (!isAppActive || _activeConversationId == null) return;
    markRead(_activeConversationId!);
  }

  Future<void> _initDatabase(
      String privateKey, MultiAuthCubit multiAuthCubit) async {
    final databaseConnection = await db.createMoorIsolate(identityNumber);
    database = Database(databaseConnection);
    attachmentUtil = AttachmentUtil.init(
      client,
      database.messageDao,
      database.transcriptMessageDao,
      identityNumber,
    );
    _sendMessageHelper = SendMessageHelper(database, attachmentUtil);
    blaze = Blaze(
      userId,
      sessionId,
      privateKey,
      database,
      client,
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
      this.privateKey,
      attachmentUtil,
      multiAuthCubit,
    );

    await initKeyValues();
  }

  late String userId;
  late String sessionId;
  late String identityNumber;
  late PrivateKey privateKey;

  late Client client;
  late Database database;
  late Blaze blaze;
  late DecryptMessage _decryptMessage;
  late Sender _sender;
  late SendMessageHelper _sendMessageHelper;
  late AttachmentUtil attachmentUtil;

  late SignalProtocol signalProtocol;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  String? _activeConversationId;

  final jobSubscribers = <StreamSubscription>{};

  void start() {
    blaze.connect();

    final primarySessionId = AccountKeyValue.instance.primarySessionId;
    if (primarySessionId != null) {
      jobSubscribers.add(database.jobDao
          .watchHasSessionAckJobs()
          .asyncListen((_) => _runSessionAckJob()));
    }

    jobSubscribers
      ..add(Rx.merge([
        // runFloodJob when socket connected.
        blaze.connectedStateBehaviorSubject.stream
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
    final floodMessages =
        await database.floodMessageDao.findFloodMessage().get();
    if (floodMessages.isEmpty) {
      return;
    }
    for (final message in floodMessages) {
      Stopwatch? stopwatch;
      if (!kReleaseMode) {
        stopwatch = Stopwatch()..start();
      }

      await _decryptMessage.process(message);

      if (stopwatch != null) {
        d('process execution time: ${stopwatch.elapsedMilliseconds}');
      }
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
    final primarySessionId = AccountKeyValue.instance.primarySessionId;
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

      final message = await database.messageDao.sendingMessage(messageId);
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
        message.content = await jsonEncodeWithIsolate(json);
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

  Future<void> signOutAndClear() async {
    await client.accountApi.logout(LogoutRequest(sessionId));
    await Future.wait(jobSubscribers.map((s) => s.cancel()));
    jobSubscribers.clear();
    await clearKeyValues();
    // Re-init keyValue to prepare for next login.
    await initKeyValues();
    await SignalDatabase.get.clear();
    await database.participantSessionDao.deleteBySessionId(sessionId);
    await database.participantSessionDao.updateSentToServer();

    clearWebViewCacheAndCookies();
  }

  Future<void> sendTextMessage(
    String content,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
    bool silent = false,
  }) async {
    if (content.isEmpty) return;
    await _sendMessageHelper.sendTextMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      encryptCategory,
      content,
      quoteMessageId: quoteMessageId,
      silent: silent,
    );
  }

  Future<void> sendPostMessage(
    String content,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
  }) async {
    if (content.isEmpty) return;
    await _sendMessageHelper.sendPostMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      content,
      encryptCategory,
    );
  }

  Future<void> sendImageMessage(
    EncryptCategory encryptCategory, {
    XFile? file,
    Uint8List? bytes,
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
  }) async =>
      _sendMessageHelper.sendImageMessage(
        conversationId: await _initConversation(conversationId, recipientId),
        senderId: userId,
        file: file,
        bytes: bytes,
        category: encryptCategory.toCategory(MessageCategory.plainImage,
            MessageCategory.signalImage, MessageCategory.encryptedImage),
        quoteMessageId: quoteMessageId,
      );

  // NOTE: Send video as DataMessage, cause we can not retriever video metadata
  // from video file.
  Future<void> sendVideoMessage(XFile video, EncryptCategory encryptCategory,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendDataMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          video,
          encryptCategory.toCategory(MessageCategory.plainData,
              MessageCategory.signalData, MessageCategory.encryptedData),
          quoteMessageId);

  Future<void> sendAudioMessage(XFile audio, EncryptCategory encryptCategory,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendAudioMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          audio,
          encryptCategory.toCategory(MessageCategory.plainAudio,
              MessageCategory.signalAudio, MessageCategory.encryptedAudio),
          quoteMessageId);

  Future<void> sendDataMessage(XFile file, EncryptCategory encryptCategory,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendDataMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          file,
          encryptCategory.toCategory(MessageCategory.plainData,
              MessageCategory.signalData, MessageCategory.encryptedData),
          quoteMessageId);

  Future<void> sendStickerMessage(
    String stickerId,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
  }) async =>
      _sendMessageHelper.sendStickerMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          StickerMessage(stickerId, null, null),
          encryptCategory.toCategory(MessageCategory.plainSticker,
              MessageCategory.signalSticker, MessageCategory.encryptedSticker));

  Future<void> sendContactMessage(String shareUserId, String shareUserFullName,
          EncryptCategory encryptCategory,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendContactMessage(
        await _initConversation(conversationId, recipientId),
        userId,
        ContactMessage(shareUserId),
        shareUserFullName,
        encryptCategory: encryptCategory,
        quoteMessageId: quoteMessageId,
      );

  Future<void> sendRecallMessage(List<String> messageIds,
          {String? conversationId, String? recipientId}) async =>
      _sendMessageHelper.sendRecallMessage(
          await _initConversation(conversationId, recipientId), messageIds);

  Future<void> forwardMessage(
    String forwardMessageId,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
  }) async =>
      _sendMessageHelper.forwardMessage(
        await _initConversation(conversationId, recipientId),
        userId,
        forwardMessageId,
        encryptCategory: encryptCategory,
      );

  void selectConversation(String? conversationId) {
    _decryptMessage.conversationId = conversationId;
    _activeConversationId = conversationId;
  }

  Future<void> markRead(String conversationId) async {
    final ids =
        await database.messageDao.getUnreadMessageIds(conversationId, userId);
    if (ids.isEmpty) return;
    final jobs = ids
        .map((id) =>
            createAckJob(kAcknowledgeMessageReceipts, id, MessageStatus.read))
        .toList();
    await database.jobDao.insertAll(jobs);
    await _createReadSessionMessage(ids);
  }

  Future<void> _createReadSessionMessage(List<String> messageIds) async {
    final primarySessionId = AccountKeyValue.instance.primarySessionId;
    if (primarySessionId == null) {
      return;
    }
    final jobs = messageIds
        .map((id) => createAckJob(kCreateMessage, id, MessageStatus.read))
        .toList();
    await database.jobDao.insertAll(jobs);
  }

  Future<void> stop() async {
    appActiveListener.removeListener(onActive);
    checkSignalKeyTimer?.cancel();
    blaze.dispose();
    await database.dispose();
  }

  void release() {
    // todo release resource
  }

  Future<void> refreshSelf() async {
    final me = (await client.accountApi.getMe()).data;
    await database.userDao.insert(db.User(
      userId: me.userId,
      identityNumber: me.identityNumber,
      relationship:
          const UserRelationshipJsonConverter().fromJson(me.relationship),
      fullName: me.fullName,
      avatarUrl: me.avatarUrl,
      phone: me.phone,
      isVerified: me.isVerified,
      createdAt: me.createdAt,
      muteUntil: DateTime.tryParse(me.muteUntil),
      biography: me.biography,
      isScam: me.isScam ? 1 : 0,
    ));
    multiAuthCubit.updateAccount(me);
  }

  Future<void> refreshFriends() async {
    final friends = (await client.accountApi.getFriends()).data;
    await _decryptMessage.insertUpdateUsers(friends);
  }

  Future<void> checkSignalKeys() async {
    final hasPushSignalKeys = PrivacyKeyValue.instance.hasPushSignalKeys;
    if (hasPushSignalKeys) {
      unawaited(checkSignalKey(client));
    } else {
      await refreshSignalKeys(client);
      PrivacyKeyValue.instance.hasPushSignalKeys = true;
    }
  }

  Future<void> syncSession() async {
    final hasSyncSession = PrivacyKeyValue.instance.hasSyncSession;
    if (hasSyncSession) {
      return;
    }
    final sessionDao = SignalDatabase.get.sessionDao;
    final senderKeyDao = SignalDatabase.get.senderKeyDao;
    final sessions = await sessionDao.getSessionAddress();
    final userIds = sessions.map((e) => e.address).toList();
    final response = await client.userApi.getSessions(userIds);
    final sessionMap = <String, int>{};
    final userSessionMap = <String, String>{};
    response.data.forEach((e) {
      if (e.platform == 'Android' || e.platform == 'iOS') {
        final deviceId = e.sessionId.getDeviceId();
        sessionMap[e.userId] = deviceId;
        userSessionMap[e.userId] = e.sessionId;
      }
    });
    if (sessionMap.isEmpty) {
      return;
    }
    final newSessions = <SessionsCompanion>[];
    for (final s in sessions) {
      sessionMap.values.forEach((d) {
        newSessions.add(SessionsCompanion.insert(
            address: s.address,
            device: d,
            record: s.record,
            timestamp: s.timestamp));
      });
    }
    await sessionDao.insertList(newSessions);
    final senderKeys = await senderKeyDao.getSenderKeys();
    for (final key in senderKeys) {
      if (!key.senderId.endsWith(':1')) {
        continue;
      }
      final userId = key.senderId.substring(0, key.senderId.length - 2);
      final d = sessionMap[userId];
      if (d != null) {
        await senderKeyDao.insert(SenderKey(
            groupId: key.groupId, senderId: '$userId$d', record: key.record));
      }
    }

    final participants = await database.participantDao.getAllParticipants();
    final newParticipantSessions = <db.ParticipantSessionData>[];
    participants.forEach((p) {
      final sessionId = userSessionMap[p.userId];
      if (sessionId != null) {
        final ps = db.ParticipantSessionData(
            conversationId: p.conversationId,
            userId: p.userId,
            sessionId: sessionId);
        newParticipantSessions.add(ps);
      }
    });
    await database.participantSessionDao.insertAll(newParticipantSessions);
    PrivacyKeyValue.instance.hasSyncSession = true;
  }

  Future<void> initSticker() async {
    final refreshStickerLastTime =
        AccountKeyValue.instance.refreshStickerLastTime;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - refreshStickerLastTime < hours24) {
      return;
    }

    final res = await client.accountApi.getStickerAlbums();
    res.data.forEach((item) async {
      await database.stickerAlbumDao.insert(db.StickerAlbum(
          albumId: item.albumId,
          name: item.name,
          iconUrl: item.iconUrl,
          createdAt: item.createdAt,
          updateAt: item.updateAt,
          userId: item.userId,
          category: item.category,
          description: item.description));
      await _updateStickerAlbums(item.albumId);
    });

    AccountKeyValue.instance.refreshStickerLastTime = now;
  }

  final refreshUserIdSet = <dynamic>{};

  Future<void> initCircles() async {
    final hasSyncCircle = AccountKeyValue.instance.hasSyncCircle;
    if (hasSyncCircle) {
      return;
    }

    refreshUserIdSet.clear();
    final res = await client.circleApi.getCircles();
    await Future.forEach<CircleResponse>(res.data, (circle) async {
      await database.circleDao.insertUpdate(db.Circle(
          circleId: circle.circleId,
          name: circle.name,
          createdAt: circle.createdAt));
      await handleCircle(circle);
    });

    AccountKeyValue.instance.hasSyncCircle = true;
  }

  Future<void> handleCircle(CircleResponse circle, {int? offset}) async {
    final ccList =
        (await client.circleApi.getCircleConversations(circle.circleId)).data;
    for (final cc in ccList) {
      await database.circleConversationDao.insert(db.CircleConversation(
        conversationId: cc.conversationId,
        circleId: cc.circleId,
        createdAt: cc.createdAt,
      ));
      await _decryptMessage.syncConversion(cc.conversationId);
      if (cc.userId != null && !refreshUserIdSet.contains(cc.userId)) {
        final u = await database.userDao.userById(cc.userId!).getSingleOrNull();
        if (u == null) {
          refreshUserIdSet.add(cc.userId);
        }
      }
    }
    if (ccList.length >= 500) {
      await handleCircle(circle, offset: offset ?? 0 + 500);
    }
  }

  Future<void> _updateStickerAlbums(String albumId) async {
    try {
      final response = await client.accountApi.getStickersByAlbumId(albumId);
      final relationships = <db.StickerRelationship>[];
      response.data.forEach((sticker) {
        relationships.add(db.StickerRelationship(
            albumId: albumId, stickerId: sticker.stickerId));
        database.stickerDao.insert(db.Sticker(
          stickerId: sticker.stickerId,
          albumId: albumId,
          name: sticker.name,
          assetUrl: sticker.assetUrl,
          assetType: sticker.assetType,
          assetWidth: sticker.assetWidth,
          assetHeight: sticker.assetHeight,
          createdAt: sticker.createdAt,
        ));
      });

      await database.stickerRelationshipDao.insertAll(relationships);
    } catch (e, s) {
      w('Update sticker albums error: $e, stack: $s');
    }
  }

  Future<String?> downloadAttachment(db.MessageItem message) async {
    AttachmentMessage? attachmentMessage;
    final m =
        await database.messageDao.findMessageByMessageId(message.messageId);
    if (m != null) {
      attachmentMessage = AttachmentMessage(
        m.mediaKey,
        m.mediaDigest,
        m.content!,
        m.mediaMimeType!,
        m.mediaSize!,
        m.name,
        m.mediaWidth,
        m.mediaHeight,
        m.thumbImage,
        int.tryParse(m.mediaDuration ?? '0'),
        m.mediaWaveform,
        null,
        null,
      );
    }
    if (attachmentMessage == null) {
      final m = await database.transcriptMessageDao
          .transcriptMessageByMessageId(message.messageId)
          .getSingleOrNull();

      if (m != null) {
        attachmentMessage = AttachmentMessage(
          m.mediaKey,
          m.mediaDigest,
          m.content!,
          m.mediaMimeType!,
          m.mediaSize!,
          m.userFullName,
          m.mediaWidth,
          m.mediaHeight,
          m.thumbImage,
          int.tryParse(m.mediaDuration ?? '0'),
          m.mediaWaveform,
          null,
          null,
        );
      }
    }
    await attachmentUtil.downloadAttachment(
      content: message.content!,
      messageId: message.messageId,
      conversationId: message.conversationId,
      category: message.type,
      attachmentMessage: attachmentMessage,
    );
  }

  Future<void> reUploadAttachment(db.MessageItem message) =>
      _sendMessageHelper.reUploadAttachment(
        message.conversationId,
        message.messageId,
        message.type,
        File(convertMessageAbsolutePath(message)),
        message.mediaName,
        message.mediaMimeType!,
        message.mediaSize!,
        message.mediaWidth,
        message.mediaHeight,
        message.thumbImage,
        message.mediaDuration,
        message.mediaWaveform,
        message.content,
      );

  Future<void> addUser(String userId, String? fullName) =>
      _relationship(RelationshipRequest(
        userId: userId,
        action: RelationshipAction.add,
        fullName: fullName,
      ));

  Future<void> removeUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.remove));

  Future<void> blockUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.block));

  Future<void> unblockUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.unblock));

  Future<void> _relationship(RelationshipRequest request) async {
    try {
      final response = await client.userApi.relationships(request);
      await database.userDao.insertSdkUser(response.data);
    } catch (e) {
      w('_relationship error $e');
    }
  }

  Future<void> createGroupConversation(
    String name,
    List<String> userIds,
  ) async {
    final conversationId = const Uuid().v4();

    final response = await client.conversationApi.createConversation(
      ConversationRequest(
        conversationId: conversationId,
        category: ConversationCategory.group,
        name: name.trim(),
        participants:
            userIds.map((e) => ParticipantRequest(userId: e)).toList(),
      ),
    );
    await database.conversationDao.updateConversation(response.data);
    await addParticipant(conversationId, userIds);
  }

  Future<void> exitGroup(String conversationId) =>
      client.conversationApi.exit(conversationId);

  Future<void> joinGroup(String code) async {
    final response = await client.conversationApi.join(code);
    await database.conversationDao.updateConversation(response.data);
  }

  Future<void> addParticipant(
    String conversationId,
    List<String> userIds,
  ) async {
    try {
      final response = await client.conversationApi.participants(
        conversationId,
        'ADD',
        userIds.map((e) => ParticipantRequest(userId: e)).toList(),
      );

      await database.conversationDao.updateConversation(response.data);
    } catch (e) {
      w('addParticipant error $e');
      // throw error??
    }
  }

  Future<void> removeParticipant(
    String conversationId,
    String userId,
  ) async {
    try {
      await client.conversationApi.participants(
        conversationId,
        'REMOVE',
        [ParticipantRequest(userId: userId)],
      );
    } catch (e) {
      w('removeParticipant error $e');
      rethrow;
    }
  }

  Future<void> updateParticipantRole(
      String conversationId, String userId, ParticipantRole? role) async {
    try {
      await client.conversationApi.participants(conversationId, 'ROLE',
          [ParticipantRequest(userId: userId, role: role)]);
    } catch (e) {
      w('updateParticipantRole error $e');
      rethrow;
    }
  }

  Future<void> createCircle(
      String name, List<CircleConversationRequest> list) async {
    final response =
        await client.circleApi.createCircle(CircleName(name: name));

    await database.circleDao.insertUpdate(
      db.Circle(
        circleId: response.data.circleId,
        name: response.data.name,
        createdAt: response.data.createdAt,
      ),
    );

    await editCircleConversation(
      response.data.circleId,
      list,
    );
  }

  Future<void> updateCircle(String circleId, String name) async {
    final response = await client.circleApi.updateCircle(
      circleId,
      CircleName(name: name),
    );
    await database.circleDao.insertUpdate(db.Circle(
      circleId: response.data.circleId,
      name: response.data.name,
      createdAt: response.data.createdAt,
    ));
  }

  Future<String> _initConversation(String? cid, String? recipientId) async {
    if (recipientId != null) {
      final conversationId = generateConversationId(recipientId, userId);
      if (cid != null) {
        assert(cid == conversationId);
      }
      final conversation = await database.conversationDao
          .conversationById(conversationId)
          .getSingleOrNull();
      if (conversation == null) {
        await database.conversationDao.insert(db.Conversation(
            conversationId: conversationId,
            category: ConversationCategory.contact,
            createdAt: DateTime.now(),
            ownerId: recipientId,
            status: ConversationStatus.start));
        await database.participantDao.insert(db.Participant(
            conversationId: conversationId,
            userId: userId,
            createdAt: DateTime.now()));
        await database.participantDao.insert(db.Participant(
            conversationId: conversationId,
            userId: recipientId,
            createdAt: DateTime.now()));
      }
      return conversationId;
    } else if (cid != null) {
      return cid;
    } else {
      throw Exception('Parameter error');
    }
  }

  Future<void> editContactName(String userId, String name) =>
      _relationship(RelationshipRequest(
          userId: userId, fullName: name, action: RelationshipAction.update));

  Future<void> circleRemoveConversation(
    String circleId,
    String conversationId,
  ) async {
    await client.circleApi.updateCircleConversations(circleId, [
      CircleConversationRequest(
          action: CircleConversationAction.remove,
          conversationId: conversationId,
          userId: userId)
    ]);
    await database.circleConversationDao.deleteByIds(conversationId, circleId);
  }

  Future<void> editCircleConversation(
    String circleId,
    List<CircleConversationRequest> list,
  ) async {
    if (list.isEmpty) return;
    final response = await client.circleApi.updateCircleConversations(
      circleId,
      list,
    );
    await database.transaction(() => Future.wait(
          response.data.map(
            (cc) async {
              await database.circleConversationDao.insert(
                db.CircleConversation(
                  conversationId: cc.conversationId,
                  circleId: cc.circleId,
                  createdAt: cc.createdAt,
                ),
              );
              if (cc.userId != null && !refreshUserIdSet.contains(cc.userId)) {
                final u = await database.userDao
                    .userById(cc.userId!)
                    .getSingleOrNull();
                if (u == null) {
                  refreshUserIdSet.add(cc.userId);
                }
              }
            },
          ),
        ));
  }

  Future<void> deleteCircle(String circleId) async {
    try {
      await client.circleApi.deleteCircle(circleId);
    } catch (e) {
      if (e is! MixinApiError || (e.error as MixinError).code != notFound) {
        rethrow;
      }
    }

    await database.transaction(() async {
      await database.circleDao.deleteCircleById(circleId);
      await database.circleConversationDao.deleteByCircleId(circleId);
    });
  }

  Future<void> report(String userId) async {
    final response = await client.userApi.report(
        RelationshipRequest(userId: userId, action: RelationshipAction.block));
    await database.userDao.insertSdkUser(response.data);
  }

  Future<void> unMuteConversation({
    String? conversationId,
    String? userId,
  }) async {
    await _mute(
      0,
      conversationId: conversationId,
      userId: userId,
    );
  }

  Future<void> muteConversation(
    int duration, {
    String? conversationId,
    String? userId,
  }) async {
    await _mute(
      duration,
      conversationId: conversationId,
      userId: userId,
    );
  }

  Future<void> _mute(
    int duration, {
    String? conversationId,
    String? userId,
  }) async {
    assert([conversationId, userId].any((element) => element != null));
    assert(![conversationId, userId].every((element) => element != null));
    MixinResponse<ConversationResponse> response;
    if (conversationId != null) {
      response = await client.conversationApi.mute(
        conversationId,
        ConversationRequest(
          conversationId: conversationId,
          category: ConversationCategory.group,
          duration: duration,
        ),
      );
    } else {
      final cid = generateConversationId(userId!, this.userId);
      response = await client.conversationApi.mute(
        cid,
        ConversationRequest(
          conversationId: cid,
          category: ConversationCategory.contact,
          duration: duration,
          participants: [ParticipantRequest(userId: this.userId)],
        ),
      );
    }
    final cr = response.data;
    if (cr.category == ConversationCategory.contact) {
      if (userId != null) {
        await database.userDao.updateMuteUntil(userId, cr.muteUntil);
      }
    } else {
      if (conversationId != null) {
        await database.conversationDao
            .updateMuteUntil(conversationId, cr.muteUntil);
      }
    }
  }

  Future<void> editGroup(
    String conversationId, {
    String? announcement,
    String? name,
  }) async {
    final response = await client.conversationApi.update(
      conversationId,
      ConversationRequest(
        conversationId: conversationId,
        announcement: announcement,
        name: name,
      ),
    );

    await database.conversationDao.updateConversation(response.data);
  }

  Future<void> refreshGroup(String conversationId) async {
    final response =
        await client.conversationApi.getConversation(conversationId);
    await database.conversationDao.updateConversation(response.data);
  }

  Future<void> rotate(String conversationId) async {
    final response = await client.conversationApi.rotate(conversationId);
    await database.conversationDao
        .updateCodeUrl(conversationId, response.data.codeUrl);
  }

  Future<void> unpin(String conversationId) =>
      database.conversationDao.unpin(conversationId);

  Future<void> pin(String conversationId) =>
      database.conversationDao.pin(conversationId);

  Future<int> getConversationMediaSize(String conversationId) async =>
      (await getTotalSizeOfFile(attachmentUtil.getImagesPath(conversationId))) +
      (await getTotalSizeOfFile(attachmentUtil.getVideosPath(conversationId))) +
      (await getTotalSizeOfFile(attachmentUtil.getAudiosPath(conversationId))) +
      (await getTotalSizeOfFile(attachmentUtil.getFilesPath(conversationId)));

  String getImagesPath(String conversationId) =>
      attachmentUtil.getImagesPath(conversationId);

  String getVideosPath(String conversationId) =>
      attachmentUtil.getVideosPath(conversationId);

  String getAudiosPath(String conversationId) =>
      attachmentUtil.getAudiosPath(conversationId);

  String getFilesPath(String conversationId) =>
      attachmentUtil.getFilesPath(conversationId);

  String getMediaFilePath() => attachmentUtil.mediaPath;

  Future<void> markMentionRead(String messageId, String conversationId) =>
      Future.wait([
        database.messageMentionDao.markMentionRead(messageId),
        (() async => database.jobDao.insert(
              db.Job(
                jobId: const Uuid().v4(),
                action: kCreateMessage,
                createdAt: DateTime.now(),
                conversationId: conversationId,
                runCount: 0,
                priority: 5,
                blazeMessage: await jsonEncodeWithIsolate(BlazeAckMessage(
                    messageId: messageId, status: 'MENTION_READ')),
              ),
            ))()
      ]);

  Future<List<db.User>?> refreshUsers(List<String> ids, {bool force = false}) =>
      _decryptMessage.refreshUsers(ids, force: force);

  Future<void> refreshConversation(String conversationId) =>
      _decryptMessage.refreshConversation(conversationId);

  Future<void> updateAccount({String? fullName, String? biography}) async {
    final user = await client.accountApi.update(AccountUpdateRequest(
      fullName: fullName,
      biography: biography,
    ));
    multiAuthCubit.updateAccount(user.data);
  }

  Future<bool> cancelProgressAttachmentJob(String messageId) =>
      attachmentUtil.cancelProgressAttachmentJob(messageId);

  Future<void> deleteMessage(String messageId) async {
    final message = await database.messageDao.findMessageByMessageId(messageId);
    if (message == null) return;
    Future<void> Function()? delete;
    if (message.category.isAttachment) {
      delete = () async {
        final path = attachmentUtil.convertAbsolutePath(
          category: message.category,
          conversationId: message.conversationId,
          fileName: message.mediaUrl,
        );
        final file = File(path);
        if (file.existsSync()) await file.delete();
      };
    } else if (message.category.isTranscript) {
      final iterable = await database.transcriptMessageDao
          .transcriptMessageByTranscriptId(message.messageId)
          .get();

      delete = () async {
        final list = await database.transcriptMessageDao
            .messageIdsByMessageIds(iterable.map((e) => e.messageId))
            .get();
        iterable
            .where((element) => !list.contains(element.messageId))
            .forEach((e) {
          final path = attachmentUtil.convertAbsolutePath(
            fileName: e.mediaUrl,
            messageId: e.messageId,
            isTranscript: true,
          );

          final file = File(path);
          if (file.existsSync()) unawaited(file.delete());
        });
      };
    }
    await database.messageDao.deleteMessage(messageId);

    unawaited(delete?.call());
  }

  String convertAbsolutePath(
          String category, String conversationId, String? fileName,
          [bool isTranscript = false]) =>
      attachmentUtil.convertAbsolutePath(
        category: category,
        conversationId: conversationId,
        fileName: fileName,
        isTranscript: isTranscript,
      );

  String convertMessageAbsolutePath(db.MessageItem? messageItem,
      [bool isTranscript = false]) {
    if (messageItem == null) return '';
    return convertAbsolutePath(messageItem.type, messageItem.conversationId,
        messageItem.mediaUrl, isTranscript);
  }

  Future<List<db.User>?> updateUserByIdentityNumber(String identityNumber) =>
      _decryptMessage.updateUserByIdentityNumber(identityNumber);

  Future<void> pinMessage({
    required String conversationId,
    required List<PinMessageMinimal> pinMessageMinimals,
  }) =>
      _sendMessageHelper.sendPinMessage(
        conversationId: conversationId,
        senderId: userId,
        pinMessageMinimals: pinMessageMinimals,
        pin: true,
      );

  Future<void> unpinMessage({
    required String conversationId,
    required List<PinMessageMinimal> pinMessageMinimals,
  }) =>
      _sendMessageHelper.sendPinMessage(
        conversationId: conversationId,
        senderId: userId,
        pinMessageMinimals: pinMessageMinimals,
        pin: false,
      );

  Future<void> updateSnapshotById({required String snapshotId}) async {
    final data = await client.snapshotApi.getSnapshotById(snapshotId);
    await database.snapshotDao.insertSdkSnapshot(data.data);
  }

  Future<void> updateAssetById({required String assetId}) async {
    final data = await client.assetApi.getAssetById(assetId);
    await database.assetDao.insertSdkAsset(data.data);
  }

  Future<void> updateFiats() async {
    final data = await client.accountApi.getFiats();
    await database.fiatDao.insertAllSdkFiat(data.data);
  }
}
