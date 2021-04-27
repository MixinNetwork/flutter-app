import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/account/send_message_helper.dart';
import 'package:flutter_app/blaze/blaze.dart';
import 'package:flutter_app/blaze/blaze_message.dart';
import 'package:flutter_app/blaze/blaze_message_param_session.dart';
import 'package:flutter_app/blaze/blaze_param.dart';
import 'package:flutter_app/blaze/blaze_signal_key_message.dart';
import 'package:flutter_app/blaze/vo/contact_message.dart';
import 'package:flutter_app/blaze/vo/mention_user.dart';
import 'package:flutter_app/blaze/vo/sender_key_status.dart';
import 'package:flutter_app/blaze/vo/signal_key.dart';
import 'package:flutter_app/blaze/vo/sticker_message.dart';
import 'package:flutter_app/constants/constants.dart';
import 'package:flutter_app/crypto/crypto_key_value.dart';
import 'package:flutter_app/crypto/encrypted/encrypted_protocol.dart';
import 'package:flutter_app/crypto/privacy_key_value.dart';
import 'package:flutter_app/crypto/signal/signal_key_util.dart';
import 'package:flutter_app/crypto/signal/signal_database.dart';
import 'package:flutter_app/crypto/signal/signal_protocol.dart';
import 'package:flutter_app/crypto/uuid/uuid.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/extension/message_category.dart';
import 'package:flutter_app/db/mixin_database.dart' as db;
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/enum/message_category.dart';
import 'package:flutter_app/enum/message_status.dart';
import 'package:flutter_app/ui/home/bloc/multi_auth_cubit.dart';
import 'package:flutter_app/utils/attachment_util.dart';
import 'package:flutter_app/utils/file.dart';
import 'package:flutter_app/utils/load_Balancer_utils.dart';
import 'package:flutter_app/utils/stream_extension.dart';
import 'package:flutter_app/workers/decrypt_message.dart';
import 'package:flutter_app/utils/string_extension.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze.dart';
import '../blaze/blaze_message.dart';
import '../blaze/blaze_param.dart';
import '../blaze/vo/contact_message.dart';
import '../blaze/vo/sticker_message.dart';
import '../constants/constants.dart';
import '../crypto/encrypted/encrypted_protocol.dart';
import '../crypto/uuid/uuid.dart';
import '../db/database.dart';
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart' as db;
import '../db/mixin_database.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/attachment_util.dart';
import '../utils/file.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/stream_extension.dart';
import '../workers/decrypt_message.dart';
import 'send_message_helper.dart';

class AccountServer {
  static String? sid;

  set language(String language) =>
      client.dio.options.headers['Accept-Language'] = language;

  Future<void> initServer(
    String userId,
    String sessionId,
    String identityNumber,
    String privateKey,
    MultiAuthCubit multiAuthCubit,
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
          ) {
            if (e is MixinApiError && e.error.code == 401)
              multiAuthCubit.signOut();
            handler.next(e);
          },
        ),
      ],
    );
    await _initDatabase(privateKey, multiAuthCubit);
    start();
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

    _decryptMessage = DecryptMessage(
      userId,
      database,
      client,
      sessionId,
      this.privateKey,
      _attachmentUtil,
      multiAuthCubit,
    );

    signalProtocol = SignalProtocol(sessionId);
    await signalProtocol.init();

    await PrivacyKeyValue.get.init();
    await CryptoKeyValue.get.init();
  }

  late String userId;
  late String sessionId;
  late String identityNumber;
  late PrivateKey privateKey;

  late Client client;
  late Database database;
  late Blaze blaze;
  late DecryptMessage _decryptMessage;
  late SendMessageHelper _sendMessageHelper;
  late AttachmentUtil _attachmentUtil;

  late SignalProtocol signalProtocol;

  final EncryptedProtocol _encryptedProtocol = EncryptedProtocol();

  void start() {
    blaze.connect();
    database.floodMessagesDao
        .findFloodMessage()
        .where((list) => list.isNotEmpty)
        .asyncMapDrop((list) async {
      for (final message in list) {
        await _decryptMessage.process(message);
      }
      return list;
    }).listen((_) {});

    database.jobsDao
        .findAckJobs()
        .where((jobs) => jobs.isNotEmpty == true)
        .asyncMapDrop(_runAckJob)
        .listen((_) {});

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
      debugPrint('Send ack error: $e, stack: $s');
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
        await blaze.deliver(blazeMessage);
        await database.jobsDao.deleteJobById(e.jobId);
      },
    );

    await Future.wait(map);
  }

  Future<void> _runSendJob(List<db.Job> jobs) async {
    jobs.where((element) => element.blazeMessage != null).forEach((job) async {
      final message =
          await database.messagesDao.sendingMessage(job.blazeMessage!);
      if (message == null) {
        await database.jobsDao.deleteJobById(job.jobId);
      } else {
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
          await blaze.deliver(blazeMessage);
          await database.messagesDao
              .updateMessageStatusById(message.messageId, MessageStatus.sent);
          await database.jobsDao.deleteJobById(job.jobId);
        } else if (message.category.isEncrypted) {
          final conversation = await database.conversationDao
              .getConversationById(message.conversationId);
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
          await blaze.deliver(blazeMessage);
          await database.messagesDao
              .updateMessageStatusById(message.messageId, MessageStatus.sent);
          await database.jobsDao.deleteJobById(job.jobId);
        } else if (message.category.isSignal) {
          // TODO check resend data

          if (!await signalProtocol.isExistSenderKey(
              message.conversationId, message.userId)) {
            _checkConversation(message.conversationId);
          }
          await _checkSessionSenderKey(message.conversationId);
          await blaze.deliverNoThrow(await encryptNormalMessage(message));
        } else {}
      }
    });
  }

  Future<BlazeMessage> encryptNormalMessage(db.SendingMessage message) async {
    // TODO resend data
    return signalProtocol.encryptGroupMessage(
        message, await getMentionData(message.messageId));
  }

  Future<List<String>?> getMentionData(String messageId) async {
    final mentionData =
        await database.messageMentionsDao.getMentionData(messageId);
    if (mentionData == null) {
      return null;
    }
    final Iterable list = json.decode(mentionData);
    final mentionUsers =
        List<MentionUser>.from(list.map((e) => MentionUser.fromJson(e)));
    final ids = mentionUsers.map((e) => e.identityNumber);
    return database.userDao.findMultiUserIdsByIdentityNumbers(ids);
  }

  Future _checkSessionSenderKey(String conversationId) async {
    final participants = await database.participantSessionDao
        .getNotSendSessionParticipants(conversationId, userId);
    if (participants.isEmpty) {
      return;
    }
    final requestSignalKeyUsers = <BlazeMessageParamSession>[];
    final signalKeyMessages = <BlazeSignalKeyMessage>[];
    for (final p in participants) {
      if (!await signalProtocol.containsSession(p.userId,
          deviceId: p.sessionId.getDeviceId())) {
        requestSignalKeyUsers.add(
            BlazeMessageParamSession(userId: p.userId, sessionId: p.sessionId));
      } else {
        final encryptedResult = await signalProtocol.encryptSenderKey(
            conversationId, p.userId,
            deviceId: p.sessionId.getDeviceId());
        if (encryptedResult.err) {
          requestSignalKeyUsers.add(BlazeMessageParamSession(
              userId: p.userId, sessionId: p.sessionId));
        } else {
          signalKeyMessages.add(createBlazeSignalKeyMessage(
              p.userId, encryptedResult.result!,
              sessionId: p.sessionId));
        }
      }
    }

    if (requestSignalKeyUsers.isNotEmpty) {
      final blazeMessage = createConsumeSessionSignalKeys(
          createConsumeSignalKeysParam(requestSignalKeyUsers));
      final data = (await blaze.deliverAndWait(blazeMessage))?.data;
      if (data != null) {
        final signalKeys =
            List<SignalKey>.from(data.values.map((e) => SignalKey.fromJson(e)));
        final keys = <BlazeMessageParamSession>[];
        if (signalKeys.isNotEmpty) {
          for (final k in signalKeys) {
            final preKeyBundle = k.createPreKeyBundle();
            signalProtocol.processSession(k.userId, preKeyBundle);
            final encryptedResult = await signalProtocol.encryptSenderKey(
                conversationId, k.userId,
                deviceId: preKeyBundle.getDeviceId());
            signalKeyMessages.add(createBlazeSignalKeyMessage(
                k.userId, encryptedResult.result!,
                sessionId: k.sessionId));
            keys.add(BlazeMessageParamSession(
                userId: k.userId, sessionId: k.sessionId));
          }
        } else {
          debugPrint(
              'No any group signal key from server: ${requestSignalKeyUsers.toString()}');
        }

        final noKeyList = requestSignalKeyUsers.where((e) => !keys.contains(e));
        if (noKeyList.isNotEmpty) {
          final sentSenderKeys = noKeyList
              .map((e) => db.ParticipantSessionData(
                  conversationId: conversationId,
                  userId: e.userId,
                  sessionId: e.sessionId))
              .toList();
          await database.participantSessionDao.updateList(sentSenderKeys);
        }
      }
    }
    if (signalKeyMessages.isEmpty) {
      return;
    }
    final checksum = await getCheckSum(conversationId);
    final bm = createSignalKeyMessage(createSignalKeyMessageParam(
        conversationId, signalKeyMessages, checksum));
    final result = await blaze.deliverNoThrow(bm);
    if (result.retry) {
      return _checkSessionSenderKey(conversationId);
    }
    if (result.success) {
      final sentSenderKeys = signalKeyMessages
          .map((e) => db.ParticipantSessionData(
              conversationId: conversationId,
              userId: e.recipientId,
              sessionId: e.sessionId!,
              sentToServer: SenderKeyStatus.sent.index))
          .toList();
      await database.participantSessionDao.updateList(sentSenderKeys);
    }
  }

  Future<String> getCheckSum(String conversationId) async {
    final sessions = await database.participantSessionDao
        .getParticipantSessionsByConversationId(conversationId);
    if (sessions.isEmpty) {
      return '';
    } else {
      return generateConversationChecksum(sessions);
    }
  }

  String generateConversationChecksum(List<db.ParticipantSessionData> devices) {
    devices.sort((a, b) => a.sessionId.compareTo(b.sessionId));
    final d = devices.map((e) => e.sessionId).join('');
    return d.md5();
  }

  void _checkConversation(String conversationId) async {
    final conversation =
        await database.conversationDao.getConversationById(conversationId);
    if (conversation == null) {
      return;
    }
    if (conversation.category == ConversationCategory.group) {
      _syncConversation(conversationId);
    } else {
      _checkConversationExists(conversation);
    }
  }

  void _syncConversation(String conversationId) async {
    final res = await client.conversationApi.getConversation(conversationId);
    final conversation = res.data;
    final participants = <db.Participant>[];
    conversation.participants.map((c) => participants.add(db.Participant(
        conversationId: conversationId,
        userId: c.userId,
        createdAt: c.createdAt!)));
    database.participantsDao.replaceAll(conversationId, participants);
    if (conversation.participantSessions != null) {
      _syncParticipantSession(
          conversationId, conversation.participantSessions!);
    }
  }

  void _syncParticipantSession(
      String conversationId, List<UserSession> data) async {
    await database.participantSessionDao.deleteByStatus(conversationId);
    final remote = <db.ParticipantSessionData>[];
    data.map((s) => remote.add(db.ParticipantSessionData(
        conversationId: conversationId,
        userId: s.userId,
        sessionId: s.sessionId)));
    if (remote.isEmpty) {
      await database.participantSessionDao
          .deleteByConversationId(conversationId);
      return;
    }
    final local = await database.participantSessionDao
        .getParticipantSessionsByConversationId(conversationId);
    if (local.isEmpty) {
      await database.participantSessionDao.insertAll(remote);
      return;
    }
    final common = remote.toSet().intersection(local.toSet());
    final remove = <db.ParticipantSessionData>[];
    for (final p in local) {
      if (!common.contains(p)) {
        remove.add(p);
      }
    }
    final add = <db.ParticipantSessionData>[];
    for (final p in remote) {
      if (!common.contains(p)) {
        add.add(p);
      }
    }
    if (remove.isNotEmpty) {
      await database.participantSessionDao.deleteList(remove);
    }
    if (add.isNotEmpty) {
      await database.participantSessionDao.insertAll(add);
    }
  }

  Future<bool> _checkSignalSession(String recipientId,
      {String? senderId}) async {
    if (!await signalProtocol.containsSession(recipientId,
        deviceId: sessionId.getDeviceId())) {
      final blazeMessage = createConsumeSessionSignalKeys(
          createConsumeSignalKeysParam(<BlazeMessageParamSession>[
        BlazeMessageParamSession(userId: recipientId, sessionId: sessionId)
      ]));
      final data = (await blaze.deliverAndWait(blazeMessage))?.data;
      if (data == null) {
        return false;
      }
      final keys =
          List<SignalKey>.from(data.values.map((e) => SignalKey.fromJson(e)));
      if (keys.isNotEmpty) {
        final preKeyBundle = keys[0].createPreKeyBundle();
        signalProtocol.processSession(recipientId, preKeyBundle);
      } else {
        return false;
      }
    }
    return true;
  }

  void _checkConversationExists(db.Conversation conversation) {
    if (conversation.status != ConversationStatus.success) {
      _createConversation(conversation);
    }
  }

  Future _createConversation(db.Conversation conversation) async {
    final response = await client.conversationApi.createConversation(
      ConversationRequest(
        conversationId: conversation.conversationId,
        category: conversation.category,
        participants: <ParticipantRequest>[
          ParticipantRequest(userId: conversation.ownerId!)
        ],
      ),
    );
    await database.conversationDao.updateConversationStatusById(
        conversation.conversationId, ConversationStatus.success);

    final sessionParticipants = response.data.participantSessions;
    if (sessionParticipants != null && sessionParticipants.isNotEmpty) {
      final newParticipantSessions = <db.ParticipantSessionData>[];
      for (final p in sessionParticipants) {
        newParticipantSessions.add(db.ParticipantSessionData(
            conversationId: conversation.conversationId,
            userId: p.userId,
            sessionId: p.sessionId));
      }
      if (newParticipantSessions.isNotEmpty) {
        await database.participantSessionDao
            .replaceAll(conversation.conversationId, newParticipantSessions);
      }
    }
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

  Future<void> sendTextMessage(
    String content, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
    bool isPlain = true,
  }) async {
    if (content.isEmpty) return;
    await _sendMessageHelper.sendTextMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      content,
      isPlain: isPlain,
      quoteMessageId: quoteMessageId,
    );
  }

  Future<void> sendImageMessage(XFile image,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendImageMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          image,
          isPlain ? MessageCategory.plainImage : MessageCategory.signalImage,
          quoteMessageId);

  Future<void> sendVideoMessage(XFile video,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendVideoMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          video,
          isPlain ? MessageCategory.plainVideo : MessageCategory.signalVideo,
          quoteMessageId);

  Future<void> sendAudioMessage(XFile audio,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendAudioMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          audio,
          isPlain ? MessageCategory.plainAudio : MessageCategory.signalAudio,
          quoteMessageId);

  Future<void> sendDataMessage(XFile file,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
          String? quoteMessageId}) async =>
      _sendMessageHelper.sendDataMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          file,
          isPlain ? MessageCategory.plainData : MessageCategory.signalData,
          quoteMessageId);

  Future<void> sendStickerMessage(String stickerId,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true}) async =>
      _sendMessageHelper.sendStickerMessage(
          await _initConversation(conversationId, recipientId),
          userId,
          StickerMessage(stickerId, null, null),
          isPlain
              ? MessageCategory.plainSticker
              : MessageCategory.signalSticker);

  Future<void> sendContactMessage(String shareUserId, String shareUserFullName,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true,
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

  Future<void> forwardMessage(String forwardMessageId,
          {String? conversationId,
          String? recipientId,
          bool isPlain = true}) async =>
      _sendMessageHelper.forwardMessage(
        await _initConversation(conversationId, recipientId),
        userId,
        forwardMessageId,
        isPlain: isPlain,
      );

  void selectConversation(String? conversationId) {
    _decryptMessage.conversationId = conversationId;
    _markRead(conversationId);
  }

  Future<void> _markRead(conversationId) async {
    final ids =
        await database.messagesDao.getUnreadMessageIds(conversationId, userId);
    final status =
        EnumToString.convertToString(MessageStatus.read)!.toUpperCase();
    final now = DateTime.now();
    final jobs = ids
        .map((id) => jsonEncode(BlazeAckMessage(messageId: id, status: status)))
        .map((blazeMessage) => Job(
            jobId: const Uuid().v4(),
            action: acknowledgeMessageReceipts,
            priority: 5,
            blazeMessage: blazeMessage,
            createdAt: now,
            runCount: 0))
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

  Future pushSignalKeys() async {
    // TODO try 3 times at most
    final hasPushSignalKeys = PrivacyKeyValue.get.getHasPushSignalKeys();
    if (hasPushSignalKeys) {
      return;
    }
    await refreshSignalKeys(client);
    PrivacyKeyValue.get.setHasPushSignalKeys(true);
  }

  Future<void> syncSession() async {
    final hasSyncSession = PrivacyKeyValue.get.getHasSyncSession();
    debugPrint('syncSession start hasSyncSession: $hasSyncSession');
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
      return null;
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
    PrivacyKeyValue.get.setHasSyncSession(true);
    debugPrint(
        'syncSession end newParticipantSessions size: ${newParticipantSessions.length}');
  }

  Future<void> initSticker() async {
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
  }

  final refreshUserIdSet = <dynamic>{};

  Future<void> initCircles() async {
    refreshUserIdSet.clear();
    final res = await client.circleApi.getCircles();
    res.data.forEach((circle) async {
      await database.circlesDao.insertUpdate(Circle(
          circleId: circle.circleId,
          name: circle.name,
          createdAt: circle.createdAt,
          orderedAt: null));
      await handleCircle(circle);
    });
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
        final u =
            await database.userDao.findUserById(cc.userId!).getSingleOrNull();
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
      final relationships = <StickerRelationship>[];
      response.data.forEach((sticker) {
        relationships.add(StickerRelationship(
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
      debugPrint('$e');
      debugPrint('$s');
    }
  }

  Future<String?> downloadAttachment(db.MessageItem message) =>
      _attachmentUtil.downloadAttachment(
        content: message.content!,
        messageId: message.messageId,
        conversationId: message.conversationId,
        category: message.type,
      );

  Future<void> reUploadAttachment(db.MessageItem message) =>
      _sendMessageHelper.reUploadAttachment(
          message.conversationId,
          message.messageId,
          File(message.mediaUrl!),
          message.mediaName,
          message.mediaMimeType!,
          message.mediaSize!,
          message.mediaWidth,
          message.mediaHeight,
          message.thumbImage,
          message.mediaDuration,
          message.mediaWaveform);

  Future<void> addUser(String userId) => _relationship(
      RelationshipRequest(userId: userId, action: RelationshipAction.add));

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
      debugPrint('$e');
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
      debugPrint('$e');
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
      debugPrint('$e');
    }
  }

  Future<void> updateParticipantRole(
      String conversationId, String userId, ParticipantRole role) async {
    try {
      await client.conversationApi.participants(conversationId, 'REMOVE',
          [ParticipantRequest(userId: userId, role: role)]);
    } catch (e) {
      debugPrint('$e');
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
      final conversation =
          await database.conversationDao.getConversationById(conversationId);
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

  Future<void> editContactName(String userId, String name) async {
    // todo
  }

  Future<void> circleRemoveConversation(
    String circleId,
    String conversationId,
  ) async {
    await client.circleApi.updateCircleConversations(circleId, [
      CircleConversationRequest(
          action: CircleConversationAction.REMOVE,
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
                    .findUserById(cc.userId!)
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
      if (e is! MixinApiError || e.error.code != 404) rethrow;
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
}
