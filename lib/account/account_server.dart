import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_lifecycle/desktop_lifecycle.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:moor/moor.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_param.dart';
import '../blaze/vo/attachment_message.dart';
import '../blaze/vo/contact_message.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../blaze/vo/sticker_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/privacy_key_value.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/signal/signal_protocol.dart';
import '../crypto/uuid/uuid.dart';
import '../db/converter/message_category_type_converter.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart' as db;
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/attachment_util.dart';
import '../utils/file.dart';
import '../utils/hive_key_values.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/stream_extension.dart';
import '../utils/string_extension.dart';
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
            if (e is MixinApiError && (e.error as MixinError).code == 401) {
              await signOutAndClear();
              multiAuthCubit.signOut();
            }
            handler.next(e);
          },
        ),
      ],
      httpLogLevel: kReleaseMode ? HttpLogLevel.none : HttpLogLevel.all,
    );
    await _initDatabase(privateKey, multiAuthCubit);

    Timer.periodic(const Duration(days: 1), (timer) {
      i('refreshSignalKeys periodic');
      refreshSignalKeys(client);
    });

    start();

    DesktopLifecycle.instance.isActive.addListener(() {
      final active = DesktopLifecycle.instance.isActive.value;
      if (active && _activeConversationId != null) {
        _markRead(_activeConversationId!);
      }
    });
  }

  Future<void> _initDatabase(
      String privateKey, MultiAuthCubit multiAuthCubit) async {
    final databaseConnection = await db.createMoorIsolate(identityNumber);
    database = Database(databaseConnection);
    _attachmentUtil =
        await AttachmentUtil.init(client, database.messagesDao, identityNumber);
    _sendMessageHelper = SendMessageHelper(
        database.messagesDao, database.jobsDao, _attachmentUtil);
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
      _attachmentUtil,
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
  late AttachmentUtil _attachmentUtil;

  late SignalProtocol signalProtocol;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  String? _activeConversationId;

  bool _floodJobRunning = false;

  void start() {
    blaze.connect();

    Rx.merge([
      // runFloodJob when socket connected.
      blaze.connectedStateStreamController.stream.where((ok) => ok),
      database.mixinDatabase.tableUpdates(
        TableUpdateQuery.onTable(database.mixinDatabase.floodMessages),
      )
    ]).listen((event) => _runFloodJob());

    database.jobsDao
        .findAckJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runAckJob)
        .listen((_) {});

    final primarySessionId = AccountKeyValue.instance.primarySessionId;
    if (primarySessionId != null) {
      database.jobsDao
          .findSessionAckJobs()
          .where((jobs) => jobs.isNotEmpty == true)
          .asyncMapDrop(_runSessionAckJob)
          .listen((_) {});
    }

    database.jobsDao
        .findRecallMessageJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runRecallJob)
        .listen((_) {});

    database.jobsDao
        .findSendingJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runSendJob)
        .listen((_) {});

    // database.mock();
  }

  Future<void> _processFloodJob() async {
    final floodMessages =
        await database.floodMessagesDao.findFloodMessage().get();
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
      await database.jobsDao.deleteJobs(jobIds);
    } catch (e, s) {
      w('Send ack error: $e, stack: $s');
    }
  }

  Future<void> _runSessionAckJob(List<db.Job> jobs) async {
    final conversationId =
        await database.participantsDao.findJoinedConversationId(userId);
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
        await database.jobsDao.deleteJobs(jobIds);
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
          await database.jobsDao.deleteJobById(e.jobId);
        }
      },
    );

    await Future.wait(map);
  }

  Future<void> _runSendJob(List<db.Job> jobs) async {
    final futures =
        jobs.where((element) => element.blazeMessage != null).map((job) async {
      final message =
          await database.messagesDao.sendingMessage(job.blazeMessage!);
      if (message == null) {
        await database.jobsDao.deleteJobById(job.jobId);
        return;
      }

      MessageResult? result;

      if (message.category.isPlain ||
          message.category == MessageCategory.appCard) {
        var content = message.content;
        if (message.category == MessageCategory.appCard ||
            message.category == MessageCategory.plainPost ||
            message.category == MessageCategory.plainText) {
          final list = await utf8EncodeWithIsolate(content!);
          content = await base64EncodeWithIsolate(list);
        }
        final blazeMessage = _createBlazeMessage(message, content!);
        result = await _sender.deliver(blazeMessage);
      } else if (message.category.isEncrypted) {
        final conversation = await database.conversationDao
            .conversationById(message.conversationId)
            .getSingleOrNull();
        if (conversation == null) return;
        final participantSessionKey = await database.participantSessionDao
            .getParticipantSessionKeyWithoutSelf(
                message.conversationId, userId);
        if (participantSessionKey == null) {
          // todo throw checksum
          return;
        }
        final content = _encryptedProtocol.encryptMessage(
          privateKey,
          await utf8EncodeWithIsolate(message.content!),
          await base64DecodeWithIsolate(participantSessionKey.publicKey!),
          participantSessionKey.sessionId,
        );
        final blazeMessage = _createBlazeMessage(
            message, await base64EncodeWithIsolate(content));
        result = await _sender.deliver(blazeMessage);
      } else if (message.category.isSignal) {
        result = await _sendSignalMessage(message);
      } else {}

      if (result?.success ?? false) {
        await database.messagesDao
            .updateMessageStatusById(message.messageId, MessageStatus.sent);
        await database.conversationDao.updateConversationStatusById(
            message.conversationId, ConversationStatus.success);
        await database.jobsDao.deleteJobById(job.jobId);
      }
    });

    await Future.wait(futures);
  }

  Future<MessageResult?> _sendSignalMessage(db.SendingMessage message) async {
    MessageResult? result;
    if (message.resendStatus != null) {
      if (message.resendStatus == 1) {
        final check = await _sender.checkSignalSession(
            message.resendUserId!, message.resendSessionId!);
        if (check) {
          final encrypted = await signalProtocol.encryptSessionMessage(
              message, message.resendUserId!,
              resendMessageId: message.messageId,
              sessionId: message.resendSessionId,
              mentionData: await getMentionData(message.messageId));
          result = await _sender.deliver(encrypted);
          if (result.success) {
            await database.resendSessionMessagesDao
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
    return _sender.deliver(await encryptNormalMessage(message));
  }

  Future<BlazeMessage> encryptNormalMessage(db.SendingMessage message) async =>
      signalProtocol.encryptGroupMessage(
          message, await getMentionData(message.messageId));

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
              ].map((e) => const MessageCategoryTypeConverter().mapToSql(e)))))
        .map((row) => row.read(messages.content))
        .getSingleOrNull();

    if (content?.isEmpty ?? true) return null;
    final ids = mentionNumberRegExp.allMatches(content!).map((e) => e[1]!);
    if (ids.isEmpty) return null;
    return database.userDao.findMultiUserIdsByIdentityNumbers(ids);
  }

  BlazeMessage _createBlazeMessage(db.SendingMessage message, String data) {
    final blazeParam = BlazeMessageParam(
        conversationId: message.conversationId,
        messageId: message.messageId,
        category: message.category,
        data: data,
        quoteMessageId: message.quoteMessageId);

    return BlazeMessage(
        id: const Uuid().v4(), action: createMessage, params: blazeParam);
  }

  Future<void> signOutAndClear() async {
    await client.accountApi.logout(LogoutRequest(sessionId));
    await HiveKeyValue.clearKeyValues();
    await SignalDatabase.get.clear();
    await database.participantSessionDao.deleteBySessionId(sessionId);
    await database.participantSessionDao.updateSentToServer();
  }

  Future<void> sendTextMessage(
    String content,
    bool isPlain, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
  }) async {
    if (content.isEmpty) return;
    await _sendMessageHelper.sendTextMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      isPlain,
      content,
      quoteMessageId: quoteMessageId,
    );
  }

  Future<void> sendPostMessage(
    String content,
    bool isPlain, {
    String? conversationId,
    String? recipientId,
  }) async {
    if (content.isEmpty) return;
    await _sendMessageHelper.sendPostMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      content,
      isPlain,
    );
  }

  Future<void> sendImageMessage(
    bool isPlain, {
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
        category:
            isPlain ? MessageCategory.plainImage : MessageCategory.signalImage,
        quoteMessageId: quoteMessageId,
      );

  Future<void> sendVideoMessage(XFile video, bool isPlain,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendVideoMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          video,
          isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo,
          quoteMessageId);

  Future<void> sendAudioMessage(XFile audio, bool isPlain,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendAudioMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          audio,
          isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio,
          quoteMessageId);

  Future<void> sendDataMessage(XFile file, bool isPlain,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendDataMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          file,
          isPlain ? MessageCategory.plainData : MessageCategory.signalData,
          quoteMessageId);

  Future<void> sendStickerMessage(
    String stickerId,
    bool isPlain, {
    String? conversationId,
    String? recipientId,
  }) async =>
      _sendMessageHelper.sendStickerMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          StickerMessage(stickerId, null, null),
          isPlain
              ? MessageCategory.plainSticker
              : MessageCategory.signalSticker);

  Future<void> sendContactMessage(
          String shareUserId, String shareUserFullName, bool isPlain,
          {String? conversationId,
          String? recipientId,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendContactMessage(
        await _initConversation(conversationId, recipientId),
        userId,
        ContactMessage(shareUserId),
        shareUserFullName,
        isPlain: isPlain,
        quoteMessageId: quoteMessageId,
      );

  Future<void> sendRecallMessage(List<String> messageIds,
          {String? conversationId, String? recipientId}) async =>
      _sendMessageHelper.sendRecallMessage(
          await _initConversation(conversationId, recipientId), messageIds);

  Future<void> forwardMessage(
    String forwardMessageId,
    bool isPlain, {
    String? conversationId,
    String? recipientId,
  }) async =>
      _sendMessageHelper.forwardMessage(
        await _initConversation(conversationId, recipientId),
        userId,
        forwardMessageId,
        isPlain: isPlain,
      );

  void selectConversation(String? conversationId) {
    _decryptMessage.conversationId = conversationId;
    _activeConversationId = conversationId;
    if (conversationId != null) {
      _markRead(conversationId);
    }
  }

  Future<void> _markRead(String conversationId) async {
    final ids =
        await database.messagesDao.getUnreadMessageIds(conversationId, userId);
    final jobs = ids
        .map((id) =>
            createAckJob(acknowledgeMessageReceipts, id, MessageStatus.read))
        .toList();
    await database.jobsDao.insertAll(jobs);
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
    await database.jobsDao.insertAll(jobs);
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

  Future<void> pushSignalKeys() async {
    // TODO try 3 times at most
    final hasPushSignalKeys = PrivacyKeyValue.instance.hasPushSignalKeys;
    if (hasPushSignalKeys) {
      return;
    }
    await refreshSignalKeys(client);
    PrivacyKeyValue.instance.hasPushSignalKeys = true;
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

    final participants = await database.participantsDao.getAllParticipants();
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
      await database.stickerAlbumsDao.insert(db.StickerAlbum(
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
    res.data.forEach((circle) async {
      await database.circlesDao.insertUpdate(db.Circle(
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

      await database.stickerRelationshipsDao.insertAll(relationships);
    } catch (e, s) {
      w('Update sticker albums error: $e, stack: $s');
    }
  }

  Future<String?> downloadAttachment(db.MessageItem message) async {
    AttachmentMessage? attachmentMessage;
    if (message.content != null) {
      try {
        attachmentMessage = AttachmentMessage.fromJson(
            await jsonBase64DecodeWithIsolate(message.content!));
      } catch (e) {
        attachmentMessage = null;
      }
    }
    await _attachmentUtil.downloadAttachment(
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
        File(message.mediaUrl!),
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
    for (final userId in userIds) {
      await addParticipant(conversationId, userId);
    }
  }

  Future<void> exitGroup(String conversationId) async {
    final response = await client.conversationApi.exit(conversationId);
    await database.conversationDao.updateConversation(response.data);
  }

  Future<void> addParticipant(
    String conversationId,
    String userId,
  ) async {
    try {
      final response = await client.conversationApi.participants(
          conversationId, 'ADD', [ParticipantRequest(userId: userId)]);

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

    await database.circlesDao.insertUpdate(
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
    await database.circlesDao.insertUpdate(db.Circle(
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
        await database.participantsDao.insert(db.Participant(
            conversationId: conversationId,
            userId: userId,
            createdAt: DateTime.now()));
        await database.participantsDao.insert(db.Participant(
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
      if (e is! MixinApiError || (e.error as MixinError).code != 404) rethrow;
    }

    await database.transaction(() async {
      await database.circlesDao.deleteCircleById(circleId);
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
      (await getTotalSizeOfFile(
          _attachmentUtil.getImagesPath(conversationId))) +
      (await getTotalSizeOfFile(
          _attachmentUtil.getVideosPath(conversationId))) +
      (await getTotalSizeOfFile(
          _attachmentUtil.getAudiosPath(conversationId))) +
      (await getTotalSizeOfFile(_attachmentUtil.getFilesPath(conversationId)));

  String getImagesPath(String conversationId) =>
      _attachmentUtil.getImagesPath(conversationId);

  String getVideosPath(String conversationId) =>
      _attachmentUtil.getVideosPath(conversationId);

  String getAudiosPath(String conversationId) =>
      _attachmentUtil.getAudiosPath(conversationId);

  String getFilesPath(String conversationId) =>
      _attachmentUtil.getFilesPath(conversationId);

  String getMediaFilePath() => _attachmentUtil.mediaPath;

  Future<void> markMentionRead(String messageId, String conversationId) =>
      Future.wait([
        database.messageMentionsDao.markMentionRead(messageId),
        database.jobsDao.insert(
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

  Future<List<db.User>?> refreshUsers(List<String> ids) =>
      _decryptMessage.refreshUsers(ids);

  Future<void> updateAccount({String? fullName, String? biography}) async {
    final user = await client.accountApi.update(AccountUpdateRequest(
      fullName: fullName,
      biography: biography,
    ));
    multiAuthCubit.updateAccount(user.data);
  }
}
