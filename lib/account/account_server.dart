import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:file_selector/file_selector.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_param.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/privacy_key_value.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../crypto/uuid/uuid.dart';
import '../db/dao/job_dao.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart' as db;
import '../enum/encrypt_category.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/hive_key_values.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/reg_exp_utils.dart';
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

    Timer.periodic(const Duration(days: 1), (timer) {
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

    DesktopLifecycle.instance.isActive.addListener(() {
      final active = DesktopLifecycle.instance.isActive.value;
      if (!active || _activeConversationId == null) return;
      markRead(_activeConversationId!);
    });
  }

  Future<void> _initDatabase(
      String privateKey, MultiAuthCubit multiAuthCubit) async {
    final databaseConnection = await db.createMoorIsolate(identityNumber);
    database = Database(databaseConnection);
    attachmentUtil =
        AttachmentUtil.init(client, database.messageDao, identityNumber);
    _sendMessageHelper = SendMessageHelper(
      database.messageDao,
      database.messageMentionDao,
      database.jobDao,
      database.participantDao,
      attachmentUtil,
    );
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

    await HiveKeyValue.initKeyValues();
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

  bool _floodJobRunning = false;

  final jobSubscribers = <StreamSubscription>{};

  void start() {
    blaze.connect();

    jobSubscribers
      ..add(Rx.merge([
        // runFloodJob when socket connected.
        blaze.connectedStateStreamController.stream.where((ok) => ok),
        database.mixinDatabase.tableUpdates(
          TableUpdateQuery.onTable(database.mixinDatabase.floodMessages),
        )
      ]).listen((event) => _runFloodJob()))
      ..add(database.jobDao
          .findAckJobs()
          .where((jobs) => jobs.isNotEmpty == true)
          .asyncMapDrop(_runAckJob)
          .listen((_) {}));

    final primarySessionId = AccountKeyValue.instance.primarySessionId;
    if (primarySessionId != null) {
      jobSubscribers.add(database.jobDao
          .findSessionAckJobs()
          .where((jobs) => jobs.isNotEmpty == true)
          .asyncMapDrop(_runSessionAckJob)
          .listen((_) {}));
    }

    jobSubscribers
      ..add(database.jobDao
          .findRecallMessageJobs()
          .where((jobs) => jobs.isNotEmpty == true)
          .asyncMapDrop(_runRecallJob)
          .listen((_) {}))
      ..add(database.jobDao
          .findSendingJobs()
          .where((jobs) => jobs.isNotEmpty == true)
          .asyncMapDrop(_runSendJob)
          .listen((_) {}));

    // database.mock();
  }

  Future<void> _processFloodJob() async {
    final floodMessages =
        await database.floodMessageDao.findFloodMessage().get();
    if (floodMessages.isEmpty) {
      return;
    }
    for (final message in floodMessages) {
      await _decryptMessage.process(message);
    }
    await _processFloodJob();
  }

  void _runFloodJob() {
    if (_floodJobRunning) {
      return;
    }
    _floodJobRunning = true;
    _processFloodJob().whenComplete(() {
      _floodJobRunning = false;
    });
  }

  Future<void> _runAckJob(List<db.Job> jobs) async {
    final ack = await Future.wait(
      jobs.where((element) => element.blazeMessage != null).map(
        (e) async {
          final Map map = await jsonDecodeWithIsolate(e.blazeMessage!);
          return BlazeAckMessage(
              messageId: map['message_id'], status: map['status']);
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
  }

  Future<void> _runSessionAckJob(List<db.Job> jobs) async {
    final conversationId =
        await database.participantDao.findJoinedConversationId(userId);
    if (conversationId == null) {
      return;
    }
    final ack = await Future.wait(
      jobs.where((element) => element.blazeMessage != null).map(
        (e) async {
          final Map map = await jsonDecodeWithIsolate(e.blazeMessage!);
          return BlazeAckMessage(
              messageId: map['message_id'], status: map['status']);
        },
      ),
    );
    final jobIds = jobs.map((e) => e.jobId).toList();
    final plainText = PlainJsonMessage(
        acknowledgeMessageReceipts, null, null, null, null, ack);
    final encode = base64Encode(utf8.encode(jsonEncode(plainText)));
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
  }

  Future<void> _runRecallJob(List<db.Job> jobs) async {
    final map = jobs.where((element) => element.blazeMessage != null).map(
      (e) async {
        final list = await utf8EncodeWithIsolate(e.blazeMessage!);
        final data = await base64EncodeWithIsolate(list);

        final blazeParam = BlazeMessageParam(
          conversationId: e.conversationId,
          messageId: const Uuid().v4(),
          category: MessageCategory.messageRecall,
          data: data,
        );
        final blazeMessage = BlazeMessage(
            id: const Uuid().v4(), action: createMessage, params: blazeParam);
        final result = await _sender.deliver(blazeMessage);
        if (result.success) {
          await database.jobDao.deleteJobById(e.jobId);
        }
      },
    );

    await Future.wait(map);
  }

  Future<void> _runSendJob(List<db.Job> jobs) async {
    final futures =
        jobs.where((element) => element.blazeMessage != null).map((job) async {
      assert(job.blazeMessage != null);
      String messageId;
      String? recipientId;
      var silent = false;
      try {
        final json = jsonDecode(job.blazeMessage!) as Map<String, dynamic>;
        messageId = json[JobDao.messageIdKey]!;
        recipientId = json[JobDao.recipientIdKey];
        silent = json[JobDao.silentKey];
      } catch (_) {
        messageId = job.blazeMessage!;
      }

      final message = await database.messageDao.sendingMessage(messageId);
      if (message == null) {
        await database.jobDao.deleteJobById(job.jobId);
        return;
      }

      MessageResult? result;

      var content = message.content;

      if (message.category.isPlain ||
          message.category == MessageCategory.appCard) {
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
        if (participantSessionKey == null ||
            participantSessionKey.publicKey == null) {
          // todo throw checksum
          return;
        }
        final otherSessionKey = await database.participantSessionDao
            .getOtherParticipantSessionKey(
                message.conversationId, userId, sessionId);
        if (otherSessionKey == null || otherSessionKey.publicKey == null) {
          // todo throw checksum
          return;
        }
        final content = _encryptedProtocol.encryptMessage(
            privateKey,
            await utf8EncodeWithIsolate(message.content!),
            base64.decode(base64.normalize(participantSessionKey.publicKey!)),
            participantSessionKey.sessionId,
            base64.decode(base64.normalize(otherSessionKey.publicKey!)),
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
        await database.conversationDao.updateConversationStatusById(
            message.conversationId, ConversationStatus.success);
        await database.jobDao.deleteJobById(job.jobId);
      }
    });

    await Future.wait(futures);
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
      action: createMessage,
      params: blazeParam,
    );
  }

  Future<void> signOutAndClear() async {
    await client.accountApi.logout(LogoutRequest(sessionId));
    await Future.wait(jobSubscribers.map((s) => s.cancel()));
    jobSubscribers.clear();
    await HiveKeyValue.clearKeyValues();
    await SignalDatabase.get.clear();
    await database.participantSessionDao.deleteBySessionId(sessionId);
    await database.participantSessionDao.updateSentToServer();
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
        category: encryptCategory.toCategory( MessageCategory.plainImage,
            MessageCategory.signalImage, MessageCategory.encryptedImage),
        quoteMessageId: quoteMessageId,
      );

  Future<void> sendVideoMessage(XFile video, EncryptCategory encryptCategory,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendDataMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          video,
          encryptCategory.toCategory( MessageCategory.plainVideo,
              MessageCategory.signalVideo, MessageCategory.encryptedVideo),
          quoteMessageId);

  Future<void> sendAudioMessage(XFile audio, EncryptCategory encryptCategory,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendAudioMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          audio,
          encryptCategory.toCategory( MessageCategory.plainAudio,
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
          encryptCategory.toCategory( MessageCategory.plainData,
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
          encryptCategory.toCategory( MessageCategory.plainSticker,
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
            createAckJob(acknowledgeMessageReceipts, id, MessageStatus.read))
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
        .map((id) => createAckJob(createMessage, id, MessageStatus.read))
        .toList();
    await database.jobDao.insertAll(jobs);
  }

  Future<void> stop() async {
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
      appId: null,
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
          createdAt: circle.createdAt,
          orderedAt: null));
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
    final m =
        await database.messageDao.findMessageByMessageId(message.messageId);
    if (m == null) {
      return null;
    }
    final attachmentMessage = AttachmentMessage(
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
    await attachmentUtil.downloadAttachment(
        content: message.content!,
        messageId: message.messageId,
        conversationId: message.conversationId,
        category: message.type,
        attachmentMessage: attachmentMessage);
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
      final user = response.data;
      await database.userDao.insert(db.User(
          userId: user.userId,
          identityNumber: user.identityNumber,
          relationship: user.relationship,
          fullName: user.fullName,
          avatarUrl: user.avatarUrl,
          phone: user.phone,
          isVerified: user.isVerified,
          appId: user.app?.appId,
          biography: user.biography,
          muteUntil: DateTime.tryParse(user.muteUntil),
          isScam: user.isScam ? 1 : 0,
          createdAt: user.createdAt));
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

  Future<void> exitGroup(String conversationId) async {
    final response = await client.conversationApi.exit(conversationId);
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
    final user = response.data;
    await database.userDao.insert(db.User(
      userId: user.userId,
      identityNumber: user.identityNumber,
      relationship: user.relationship,
      fullName: user.fullName,
      avatarUrl: user.avatarUrl,
      phone: user.phone,
      isVerified: user.isVerified,
      createdAt: user.createdAt,
      muteUntil: DateTime.tryParse(user.muteUntil),
      hasPin: user.hasPin == true ? 1 : 0,
      appId: user.appId,
      biography: user.biography,
      isScam: user.isScam ? 1 : 0,
    ));
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

  Future<void> editGroupAnnouncement(
    String conversationId,
    String announcement,
  ) async {
    final response = await client.conversationApi.update(
      conversationId,
      ConversationRequest(
        conversationId: conversationId,
        announcement: announcement,
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
        database.jobDao.insert(
          db.Job(
            jobId: const Uuid().v4(),
            action: createMessage,
            createdAt: DateTime.now(),
            conversationId: conversationId,
            runCount: 0,
            priority: 5,
            blazeMessage: jsonEncode(
                BlazeAckMessage(messageId: messageId, status: 'MENTION_READ')),
          ),
        )
      ]);

  Future<List<db.User>?> refreshUsers(List<String> ids, {bool force = false}) =>
      _decryptMessage.refreshUsers(ids, force: force);

  Future<void> updateAccount({String? fullName, String? biography}) async {
    final user = await client.accountApi.update(AccountUpdateRequest(
      fullName: fullName,
      biography: biography,
    ));
    multiAuthCubit.updateAccount(user.data);
  }

  Future<bool> cancelProgressAttachmentJob(String messageId) =>
      attachmentUtil.cancelProgressAttachmentJob(messageId);

  Future<void> deleteMessage(String messageId) =>
      database.messageDao.deleteMessage(messageId);

  String convertAbsolutePath(
          String category, String conversationId, String? fileName) =>
      attachmentUtil.convertAbsolutePath(category, conversationId, fileName);

  String convertMessageAbsolutePath(db.MessageItem? messageItem) {
    if (messageItem == null) return '';
    return convertAbsolutePath(
        messageItem.type, messageItem.conversationId, messageItem.mediaUrl);
  }

  Future<List<db.User>?> updateUserByIdentityNumber(String identityNumber) =>
      _decryptMessage.updateUserByIdentityNumber(identityNumber);
}
