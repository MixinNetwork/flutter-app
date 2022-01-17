import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:very_good_analysis/very_good_analysis.dart';

import '../blaze/blaze.dart';
import '../blaze/vo/pin_message_minimal.dart';
import '../constants/constants.dart';
import '../crypto/privacy_key_value.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/uuid/uuid.dart';
import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart' as db;
import '../db/mixin_database.dart';
import '../enum/encrypt_category.dart';
import '../enum/message_category.dart';
import '../enum/message_status.dart';
import '../main.dart';
import '../ui/home/bloc/multi_auth_cubit.dart';
import '../utils/app_lifecycle.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/attachment/download_key_value.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/hive_key_values.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/webview.dart';
import '../workers/injector.dart';
import '../workers/isolate_event.dart';
import '../workers/message_woker_isolate.dart';
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
    this.privateKey = privateKey;

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
            await _onClientRequestError(e);
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

    unawaited(start());

    DownloadKeyValue.instance.messageIds.forEach((messageId) {
      attachmentUtil.downloadAttachment(messageId: messageId);
    });
    appActiveListener.addListener(onActive);
  }

  Future<void> _onClientRequestError(DioError e) async {
    if (e is MixinApiError && (e.error as MixinError).code == authentication) {
      final serverTime =
          int.tryParse(e.response?.headers.value('x-server-time') ?? '');
      if (serverTime != null) {
        final time = DateTime.fromMicrosecondsSinceEpoch(serverTime ~/ 1000);
        final difference = time.difference(DateTime.now());
        if (difference.inMinutes.abs() > 5) {
          _notifyBlazeWaitSyncTime();
          return;
        }
      }
      await signOutAndClear();
      multiAuthCubit.signOut();
    }
  }

  void onActive() {
    if (!isAppActive || _activeConversationId == null) return;
    markRead(_activeConversationId!);
  }

  Future<void> _initDatabase(
      String privateKey, MultiAuthCubit multiAuthCubit) async {
    database = Database(
        await db.connectToDatabase(identityNumber, fromMainIsolate: true));
    attachmentUtil = AttachmentUtil.init(
      client,
      database.messageDao,
      database.transcriptMessageDao,
      identityNumber,
    );
    _sendMessageHelper = SendMessageHelper(database, attachmentUtil);

    _injector = Injector(userId, database, client);

    await initKeyValues();
  }

  late String userId;
  late String sessionId;
  late String identityNumber;
  late String privateKey;

  late Client client;
  late Database database;
  late Injector _injector;
  late SendMessageHelper _sendMessageHelper;
  late AttachmentUtil attachmentUtil;

  IsolateChannel<dynamic>? _isolateChannel;

  final BehaviorSubject<ConnectedState> _connectedStateBehaviorSubject =
      BehaviorSubject<ConnectedState>();

  ValueStream<ConnectedState> get connectedStateStream =>
      _connectedStateBehaviorSubject;

  Future<void> reconnectBlaze() async {
    _sendEventToWorkerIsolate(MainIsolateEventType.reconnectBlaze);
  }

  void _notifyBlazeWaitSyncTime() {
    _sendEventToWorkerIsolate(MainIsolateEventType.disconnectBlazeWithTime);
  }

  String? _activeConversationId;

  final jobSubscribers = <StreamSubscription>{};

  Future<void> start() async {
    final receivePort = ReceivePort();
    _isolateChannel = IsolateChannel<dynamic>.connectReceive(receivePort);
    final exitReceivePort = ReceivePort();
    final errorReceivePort = ReceivePort();
    await Isolate.spawn(
      startMessageProcessIsolate,
      IsolateInitParams(
        sendPort: receivePort.sendPort,
        identityNumber: identityNumber,
        userId: userId,
        sessionId: sessionId,
        privateKey: privateKey,
        mixinDocumentDirectory: mixinDocumentsDirectory.path,
        primarySessionId: AccountKeyValue.instance.primarySessionId,
        packageInfo: await packageInfoFuture,
      ),
      errorsAreFatal: false,
      onExit: exitReceivePort.sendPort,
      onError: errorReceivePort.sendPort,
    );
    jobSubscribers
      ..add(exitReceivePort.listen((message) {
        w('worker isolate service exited. $message');
        _connectedStateBehaviorSubject.add(ConnectedState.disconnected);
      }))
      ..add(errorReceivePort.listen((error) {
        e('work isolate RemoteError: $error');
      }))
      ..add(_isolateChannel!.stream.listen((event) {
        if (event is! WorkerIsolateEvent) {
          e('unexpected event from worker isolate: $event');
          return;
        }
        try {
          _handleWorkIsolateEvent(event);
        } catch (error, stacktrace) {
          e('handle worker isolate event failed: $error, $stacktrace');
        }
      }));
  }

  void _handleWorkIsolateEvent(WorkerIsolateEvent event) {
    switch (event.type) {
      case WorkerIsolateEventType.onIsolateReady:
        d('message process service ready');
        break;
      case WorkerIsolateEventType.onBlazeConnectStateChanged:
        _connectedStateBehaviorSubject.add(event.argument as ConnectedState);
        break;
      case WorkerIsolateEventType.onDbEvent:
        final args = event.argument as Tuple2<DatabaseEvent, dynamic>;
        database.mixinDatabase.eventBus.send(args.item1, args.item2);
        break;
      case WorkerIsolateEventType.onApiRequestedError:
        _onClientRequestError(event.argument as DioError);
        break;
      case WorkerIsolateEventType.requestDownloadAttachment:
        final request = event.argument as AttachmentRequest;
        _onAttachmentDownloadRequest(request);
        break;
      default:
        assert(false, 'unexpected event: $event');
        break;
    }
  }

  // Call when worker isolate process message need download attachment.
  Future<void> _onAttachmentDownloadRequest(
    AttachmentRequest request,
  ) async {
    bool needDownload(String category) {
      if (category.isImage) {
        return multiAuthCubit.state.currentPhotoAutoDownload;
      } else if (category.isVideo) {
        return multiAuthCubit.state.currentVideoAutoDownload;
      } else if (category.isData) {
        return multiAuthCubit.state.currentFileAutoDownload;
      }
      return true;
    }

    if (request is AttachmentCancelRequest) {
      d('request cancel download: ${request.messageId}');
      await attachmentUtil.cancelProgressAttachmentJob(request.messageId);
    } else if (request is AttachmentDownloadRequest) {
      d('request download: ${request.message.messageId} ${request.message.category}');
      if (needDownload(request.message.category)) {
        await attachmentUtil.downloadAttachment(
          messageId: request.message.messageId,
        );
      }
    } else if (request is TranscriptAttachmentDownloadRequest) {
      d('request download transcript: ${request.message.messageId} ${request.message.category}');
      if (needDownload(request.message.category)) {
        await attachmentUtil.downloadAttachment(
          messageId: request.message.messageId,
        );
      }
    } else {
      assert(false, 'unexpected request: $request');
    }
  }

  Future<void> signOutAndClear() async {
    _sendEventToWorkerIsolate(MainIsolateEventType.exit);
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
    _activeConversationId = conversationId;
    _sendEventToWorkerIsolate(
      MainIsolateEventType.updateSelectedConversation,
      conversationId,
    );
  }

  Future<void> markRead(String conversationId) async {
    while (true) {
      final ids = await database.messageDao
          .getUnreadMessageIds(conversationId, userId, kMarkLimit);
      if (ids.isEmpty) return;
      final jobs = ids
          .map((id) =>
              createAckJob(kAcknowledgeMessageReceipts, id, MessageStatus.read))
          .toList();
      await database.jobDao.insertAll(jobs);
      await _createReadSessionMessage(ids);
      if (ids.length < kMarkLimit) return;
    }
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
    _sendEventToWorkerIsolate(MainIsolateEventType.exit);
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
    await _injector.insertUpdateUsers(friends);
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
          sessionId: sessionId,
        );
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
      await _injector.syncConversion(cc.conversationId);
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

  Future<void> downloadAttachment(String messageId) async =>
      attachmentUtil.downloadAttachment(messageId: messageId);

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
      _injector.refreshUsers(ids, force: force);

  Future<void> refreshConversation(String conversationId) =>
      _injector.refreshConversation(conversationId);

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
      _injector.updateUserByIdentityNumber(identityNumber);

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

  Future<void> updateAssetById({required String assetId}) =>
      database.jobDao.insertUpdateAssetJob(Job(
        jobId: const Uuid().v4(),
        action: kUpdateAsset,
        priority: 5,
        runCount: 0,
        createdAt: DateTime.now(),
        blazeMessage: assetId,
      ));

  Future<void> updateFiats() async {
    final data = await client.accountApi.getFiats();
    await database.fiatDao.insertAllSdkFiat(data.data);
  }

  void _sendEventToWorkerIsolate(MainIsolateEventType type, [dynamic args]) {
    if (_isolateChannel == null) {
      d('_sendEventToWorkerIsolate: _isolateChannel is null $type');
      assert(type == MainIsolateEventType.exit);
    }
    _isolateChannel?.sink.add(type.toEvent(args));
  }
}
