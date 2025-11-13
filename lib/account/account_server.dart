import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:uuid/uuid.dart';

import '../blaze/blaze.dart';
import '../blaze/vo/pin_message_minimal.dart';
import '../constants/constants.dart';
import '../crypto/privacy_key_value.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_key_util.dart';
import '../crypto/uuid/uuid.dart';
import '../db/dao/asset_dao.dart';
import '../db/dao/sticker_album_dao.dart';
import '../db/dao/sticker_dao.dart';
import '../db/database.dart';
import '../db/extension/job.dart';
import '../db/mixin_database.dart' as db;
import '../enum/encrypt_category.dart';
import '../enum/message_category.dart';
import '../ui/provider/account_server_provider.dart';
import '../ui/provider/multi_auth_provider.dart';
import '../ui/provider/setting_provider.dart';
import '../utils/app_lifecycle.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/attachment/download_key_value.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/hive_key_values.dart';
import '../utils/logger.dart';
import '../utils/mixin_api_client.dart';
import '../utils/web_view/web_view_interface.dart';
import '../widgets/message/item/action_card/action_card_data.dart';
import '../workers/injector.dart';
import '../workers/isolate_event.dart';
import '../workers/message_worker_isolate.dart';
import 'account_key_value.dart';
import 'send_message_helper.dart';
import 'show_pin_message_key_value.dart';

class AccountServer {
  AccountServer({
    required this.multiAuthNotifier,
    required this.settingChangeNotifier,
    required this.database,
    required this.currentConversationId,
    this.userAgent,
    this.deviceId,
  });

  static String? sid;

  set language(String language) =>
      client.dio.options.headers['Accept-Language'] = language;

  final MultiAuthStateNotifier multiAuthNotifier;
  final SettingChangeNotifier settingChangeNotifier;
  final Database database;
  final GetCurrentConversationId currentConversationId;
  Timer? checkSignalKeyTimer;

  bool get _loginByPhoneNumber =>
      AccountKeyValue.instance.primarySessionId == null;
  String? userAgent;
  String? deviceId;

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

    await initKeyValues(identityNumber);

    await _initClient();

    checkSignalKeyTimer = Timer.periodic(const Duration(days: 1), (timer) {
      i('refreshSignalKeys periodic');
      checkSignalKey(client);
    });

    try {
      await checkSignalKeys();
    } on MixinApiError catch (e) {
      final err = e.error;
      if (err is MixinError && err.code == oldVersion) {
        _isUpdateRequired.value = true;
      }
      return;
    } catch (e, s) {
      w('$e, $s');
      await signOutAndClear();
      multiAuthNotifier.signOut();
      rethrow;
    }

    unawaited(_start());

    DownloadKeyValue.instance.messageIds.forEach((messageId) {
      attachmentUtil.downloadAttachment(messageId: messageId);
    });
    appActiveListener.addListener(onActive);
  }

  final BehaviorSubject<bool> _isUpdateRequired = BehaviorSubject<bool>();

  ValueStream<bool> get isUpdateRequired => _isUpdateRequired;

  Future<void> _onClientRequestError(DioException e) async {
    if (e is MixinApiError) {
      final mixinError = e.error! as MixinError;
      if (mixinError.code == authentication) {
        final serverTime = int.tryParse(
          e.response?.headers.value('x-server-time') ?? '',
        );
        if (serverTime != null) {
          final time = DateTime.fromMicrosecondsSinceEpoch(serverTime ~/ 1000);
          final deviceTime =
              e.requestOptions.extra[kRequestTimeStampKey] as DateTime?;
          final difference = time.difference(deviceTime ?? DateTime.now());
          if (difference.abs() >= const Duration(minutes: 5)) {
            _notifyBlazeWaitSyncTime();
            return;
          }
        }
        await signOutAndClear();
        multiAuthNotifier.signOut();
      } else if (mixinError.code == oldVersion) {
        _isUpdateRequired.value = true;
      }
    }
  }

  void onActive() {
    final id = currentConversationId();
    if (!isAppActive || id == null) return;
    markRead(id);
  }

  Future<void> _initClient() async {
    client = createClient(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
      loginByPhoneNumber: _loginByPhoneNumber,
      interceptors: [
        InterceptorsWrapper(
          onError: (DioException e, ErrorInterceptorHandler handler) async {
            await _onClientRequestError(e);
            handler.next(e);
          },
        ),
      ],
    )..configProxySetting(database.settingProperties);

    attachmentUtil = AttachmentUtil.init(client, database, identityNumber);
    _sendMessageHelper = SendMessageHelper(
      database,
      attachmentUtil,
      addSendingJob,
    );

    _injector = Injector(userId, database, client);
  }

  late String userId;
  late String sessionId;
  late String identityNumber;
  late String privateKey;

  late Client client;
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

  final jobSubscribers = <StreamSubscription>{};

  Future<void> _start() async {
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
        loginByPhoneNumber: _loginByPhoneNumber,
        rootIsolateToken: ServicesBinding.rootIsolateToken!,
      ),
      errorsAreFatal: false,
      onExit: exitReceivePort.sendPort,
      onError: errorReceivePort.sendPort,
    );
    jobSubscribers
      ..add(
        exitReceivePort.listen((message) {
          w('worker isolate service exited. $message');
          _connectedStateBehaviorSubject.add(ConnectedState.disconnected);
        }),
      )
      ..add(
        errorReceivePort.listen((error) {
          e('work isolate RemoteError: $error');
        }),
      )
      ..add(
        _isolateChannel!.stream.listen((event) {
          if (event is! WorkerIsolateEvent) {
            e('unexpected event from worker isolate: $event');
            return;
          }
          try {
            _handleWorkIsolateEvent(event);
          } catch (error, stacktrace) {
            e('handle worker isolate event failed: $error, $stacktrace');
          }
        }),
      );
  }

  void _handleWorkIsolateEvent(WorkerIsolateEvent event) {
    switch (event.type) {
      case WorkerIsolateEventType.onIsolateReady:
        d('message process service ready');
      case WorkerIsolateEventType.onBlazeConnectStateChanged:
        _connectedStateBehaviorSubject.add(event.argument as ConnectedState);
      case WorkerIsolateEventType.onApiRequestedError:
        _onClientRequestError(event.argument as DioException);
      case WorkerIsolateEventType.requestDownloadAttachment:
        final request = event.argument as AttachmentRequest;
        _onAttachmentDownloadRequest(request);
      case WorkerIsolateEventType.showPinMessage:
        final conversationId = event.argument as String;
        unawaited(ShowPinMessageKeyValue.instance.show(conversationId));
    }
  }

  // Call when worker isolate process message need download attachment.
  Future<void> _onAttachmentDownloadRequest(AttachmentRequest request) async {
    bool needDownload(String category) {
      if (category.isImage) {
        return settingChangeNotifier.photoAutoDownload;
      } else if (category.isVideo) {
        return settingChangeNotifier.videoAutoDownload;
      } else if (category.isData) {
        return settingChangeNotifier.fileAutoDownload;
      }
      return true;
    }

    if (request is AttachmentCancelRequest) {
      d('request cancel download: ${request.messageId}');
      await attachmentUtil.cancelProgressAttachmentJob(request.messageId);
    } else if (request is AttachmentDownloadRequest) {
      d(
        'request download: ${request.message.messageId} ${request.message.category}',
      );
      final messageId = request.message.messageId;
      if (needDownload(request.message.category)) {
        await attachmentUtil.downloadAttachment(messageId: messageId);
      } else {
        await attachmentUtil.checkSyncMessageMedia(messageId);
      }
    } else if (request is TranscriptAttachmentDownloadRequest) {
      d(
        'request download transcript: ${request.message.messageId} ${request.message.category}',
      );
      final messageId = request.message.messageId;
      if (needDownload(request.message.category)) {
        await attachmentUtil.downloadAttachment(
          messageId: request.message.messageId,
        );
      } else {
        await attachmentUtil.checkSyncMessageMedia(messageId);
      }
    } else if (request is AttachmentDeleteRequest) {
      await attachmentUtil.removeAttachmentJob(request.message.messageId);
      await _deleteMessageAttachment(request.message);
    } else {
      assert(false, 'unexpected request: $request');
    }
  }

  Future<void> signOutAndClear() async {
    _sendEventToWorkerIsolate(MainIsolateEventType.exit);
    try {
      await client.accountApi.logout(LogoutRequest(sessionId));
    } catch (error, stacktrace) {
      e('logout api error: $error, $stacktrace');
    }
    await Future.wait(jobSubscribers.map((s) => s.cancel()));
    jobSubscribers.clear();

    await clearKeyValues();

    try {
      await SignalDatabase.get.clear();
    } catch (_) {
      // ignore closed database error
    }

    try {
      await database.participantSessionDao.deleteBySessionId(sessionId);
      await database.participantSessionDao.updateSentToServer();
    } catch (_) {
      // ignore closed database error
    }

    MixinWebView.instance.clearWebViewCacheAndCookies();
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

  Future<void> sendImageMessageByUrl(
    EncryptCategory encryptCategory,
    String url,
    String previewUrl, {
    String? conversationId,
    String? recipientId,
    int? width,
    int? height,
    bool defaultGifMimeType = true,
  }) async => _sendMessageHelper.sendImageMessageByUrl(
    await _initConversation(conversationId, recipientId),
    userId,
    encryptCategory.toCategory(
      MessageCategory.plainImage,
      MessageCategory.signalImage,
      MessageCategory.encryptedImage,
    ),
    url,
    previewUrl,
    width: width,
    height: height,
    defaultGifMimeType: defaultGifMimeType,
  );

  Future<void> sendImageMessage(
    EncryptCategory encryptCategory, {
    XFile? file,
    Uint8List? bytes,
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
    bool silent = false,
    bool compress = false,
    String? caption,
  }) async => _sendMessageHelper.sendImageMessage(
    conversationId: await _initConversation(conversationId, recipientId),
    senderId: userId,
    file: file,
    bytes: bytes,
    category: encryptCategory.toCategory(
      MessageCategory.plainImage,
      MessageCategory.signalImage,
      MessageCategory.encryptedImage,
    ),
    quoteMessageId: quoteMessageId,
    silent: silent,
    compress: compress,
    caption: caption,
  );

  Future<void> sendVideoMessage(
    XFile video,
    EncryptCategory encryptCategory, {
    required int mediaWidth,
    required int mediaHeight,
    required String thumbImage,
    required String mediaDuration,
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
    bool silent = false,
  }) async {
    await _sendMessageHelper.sendVideoMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      video,
      encryptCategory.toCategory(
        MessageCategory.plainVideo,
        MessageCategory.signalVideo,
        MessageCategory.encryptedVideo,
      ),
      quoteMessageId,
      silent: silent,
      mediaDuration: mediaDuration,
      mediaHeight: mediaHeight,
      mediaWidth: mediaWidth,
      thumbImage: thumbImage,
    );
  }

  Future<void> sendAudioMessage(
    XFile audio,
    Duration duration,
    String? waveform,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
  }) async => _sendMessageHelper.sendAudioMessage(
    await _initConversation(conversationId, recipientId),
    userId,
    audio,
    encryptCategory.toCategory(
      MessageCategory.plainAudio,
      MessageCategory.signalAudio,
      MessageCategory.encryptedAudio,
    ),
    quoteMessageId,
    mediaDuration: duration.inMilliseconds.toString(),
    mediaWaveform: waveform,
  );

  Future<void> sendDataMessage(
    XFile file,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
    bool silent = false,
  }) async => _sendMessageHelper.sendDataMessage(
    await _initConversation(conversationId, recipientId),
    userId,
    file,
    encryptCategory.toCategory(
      MessageCategory.plainData,
      MessageCategory.signalData,
      MessageCategory.encryptedData,
    ),
    quoteMessageId,
    silent: silent,
  );

  Future<void> sendStickerMessage(
    String stickerId,
    String? albumId,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
  }) async => _sendMessageHelper.sendStickerMessage(
    await _initConversation(conversationId, recipientId),
    userId,
    StickerMessage(stickerId, albumId, null),
    encryptCategory.toCategory(
      MessageCategory.plainSticker,
      MessageCategory.signalSticker,
      MessageCategory.encryptedSticker,
    ),
  );

  Future<void> sendContactMessage(
    String shareUserId,
    String? shareUserFullName,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
    String? quoteMessageId,
  }) async {
    final fullName =
        shareUserFullName ??
        (await database.userDao.userById(shareUserId).getSingleOrNull())
            ?.fullName;
    return _sendMessageHelper.sendContactMessage(
      await _initConversation(conversationId, recipientId),
      userId,
      ContactMessage(shareUserId),
      fullName,
      encryptCategory: encryptCategory,
      quoteMessageId: quoteMessageId,
    );
  }

  Future<void> sendRecallMessage(
    List<String> messageIds, {
    String? conversationId,
    String? recipientId,
  }) async {
    await Future.forEach(
      messageIds,
      (id) => attachmentUtil.cancelProgressAttachmentJob(id),
    );
    return _sendMessageHelper.sendRecallMessage(
      await _initConversation(conversationId, recipientId),
      messageIds,
    );
  }

  Future<void> sendAppCardMessage({
    required AppCardData data,
    String? conversationId,
    String? recipientId,
  }) async => _sendMessageHelper.sendAppCardMessage(
    await _initConversation(conversationId, recipientId),
    userId,
    json.encode(data.toJson()),
  );

  Future<void> sendTranscriptMessage(
    List<String> messageIds,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
  }) async {
    final transcriptId = const Uuid().v4();
    db.TranscriptMessage toTranscript(db.MessageItem item) =>
        db.TranscriptMessage(
          transcriptId: transcriptId,
          messageId: item.messageId,
          userId: item.userId,
          userFullName: item.userFullName,
          category: item.type,
          createdAt: item.createdAt,
          content: item.content,
          mediaUrl: item.mediaUrl,
          mediaName: item.mediaName,
          mediaSize: item.mediaSize,
          mediaWidth: item.mediaWidth,
          mediaHeight: item.mediaHeight,
          mediaMimeType: item.mediaMimeType,
          mediaDuration: item.mediaDuration,
          mediaStatus: item.mediaStatus,
          mediaWaveform: item.mediaWaveform,
          thumbImage: item.thumbImage,
          thumbUrl: item.thumbUrl,
          stickerId: item.stickerId,
          sharedUserId: item.sharedUserId,
          quoteId: item.quoteId,
          quoteContent: item.quoteContent,
        );

    assert(messageIds.isNotEmpty);
    final messages = await database.messageDao
        .messageItemByMessageIds(messageIds)
        .get();
    final transcripts = messages
        .where((e) => e.canForward)
        .map(toTranscript)
        .toList();
    if (transcripts.isEmpty) {
      e('sendTranscriptMessage: transcripts is empty');
      return;
    }

    final nonExistent = messages.where((e) => e.type.isAttachment).any((
      message,
    ) {
      final path = attachmentUtil.convertAbsolutePath(
        fileName: message.mediaUrl,
        conversationId: message.conversationId,
        category: message.type,
      );
      final exist = path.isNotEmpty && File(path).existsSync();
      if (!exist) {
        e('sendTranscriptMessage: file not exist: $path');
      }
      return !exist;
    });

    if (nonExistent) {
      e('sendTranscriptMessage: some file[s] not exist');
      return;
    }

    await Future.wait(
      messages.where((e) => e.type.isAttachment).map((message) {
        final path = attachmentUtil.convertAbsolutePath(
          category: message.type,
          conversationId: message.conversationId,
          fileName: message.mediaUrl,
        );

        final transcriptPath = attachmentUtil.convertAbsolutePath(
          fileName: message.mediaUrl,
          messageId: message.messageId,
          isTranscript: true,
        );
        return File(path).copy(transcriptPath);
      }),
    );

    await _sendMessageHelper.sendTranscriptMessage(
      conversationId: await _initConversation(conversationId, recipientId),
      senderId: userId,
      transcripts: transcripts,
      encryptCategory: encryptCategory,
    );
  }

  Future<void> forwardMessage(
    String forwardMessageId,
    EncryptCategory encryptCategory, {
    String? conversationId,
    String? recipientId,
  }) async => _sendMessageHelper.forwardMessage(
    await _initConversation(conversationId, recipientId),
    userId,
    forwardMessageId,
    encryptCategory: encryptCategory,
  );

  void selectConversation(String? conversationId) {
    _sendEventToWorkerIsolate(
      MainIsolateEventType.updateSelectedConversation,
      conversationId,
    );
  }

  void addAckJob(List<db.Job> jobs) {
    assert(jobs.every((job) => job.action == kAcknowledgeMessageReceipts));
    _sendEventToWorkerIsolate(MainIsolateEventType.addAckJobs, jobs);
  }

  void addSessionAckJob(List<db.Job> jobs) {
    assert(jobs.every((job) => job.action == kCreateMessage));
    _sendEventToWorkerIsolate(MainIsolateEventType.addSessionAckJobs, jobs);
  }

  void addSendingJob(db.Job job) {
    assert(
      job.action == kSendingMessage ||
          job.action == kPinMessage ||
          job.action == kRecallMessage,
    );
    _sendEventToWorkerIsolate(MainIsolateEventType.addSendingJob, job);
  }

  void addUpdateAssetJob(db.Job job) {
    assert(job.action == kUpdateAsset);
    _sendEventToWorkerIsolate(MainIsolateEventType.addUpdateAssetJob, job);
  }

  void addUpdateTokenJob(db.Job job) {
    assert(job.action == kUpdateToken);
    _sendEventToWorkerIsolate(MainIsolateEventType.addUpdateTokenJob, job);
  }

  void addUpdateStickerJob(db.Job job) {
    assert(job.action == kUpdateSticker);
    _sendEventToWorkerIsolate(MainIsolateEventType.addUpdateStickerJob, job);
  }

  void addSyncInscriptionMessageJob(String messageId) {
    _sendEventToWorkerIsolate(
      MainIsolateEventType.addSyncInscriptionMessageJob,
      createSyncInscriptionMessageJob(messageId),
    );
  }

  Future<void> markRead(String conversationId) async {
    final ids = await database.messageDao.getUnreadMessageIds(
      conversationId,
      userId,
    );

    if (ids.isEmpty) return;

    final chunked = ids.chunked(kMarkLimit);

    for (final ids in chunked) {
      final expireAt = await database.expiredMessageDao.getMessageExpireAt(ids);
      addAckJob(
        ids
            .map(
              (id) => createAckJob(
                kAcknowledgeMessageReceipts,
                id,
                MessageStatus.read,
                expireAt: expireAt[id],
              ),
            )
            .toList(),
      );

      await _createReadSessionMessage(ids, expireAt);
    }
  }

  Future<void> _createReadSessionMessage(
    List<String> messageIds,
    Map<String, int?> messageExpireAt,
  ) async {
    final primarySessionId = AccountKeyValue.instance.primarySessionId;
    if (primarySessionId == null) {
      return;
    }

    addSessionAckJob(
      messageIds
          .map(
            (id) => createAckJob(
              kCreateMessage,
              id,
              MessageStatus.read,
              expireAt: messageExpireAt[id],
            ),
          )
          .toList(),
    );
  }

  Future<void> stop() async {
    appActiveListener.removeListener(onActive);
    checkSignalKeyTimer?.cancel();
    _sendEventToWorkerIsolate(MainIsolateEventType.exit);
  }

  void release() {
    // todo release resource
  }

  Future<void> refreshSelf() async {
    final me = (await client.accountApi.getMe()).data;
    await database.userDao.insert(
      db.User(
        userId: me.userId,
        identityNumber: me.identityNumber,
        relationship: me.relationship,
        fullName: me.fullName,
        avatarUrl: me.avatarUrl,
        phone: me.phone,
        isVerified: me.isVerified,
        createdAt: me.createdAt,
        muteUntil: DateTime.tryParse(me.muteUntil),
        biography: me.biography,
        isScam: me.isScam ? 1 : 0,
        codeId: me.codeId,
        codeUrl: me.codeUrl,
        membership: me.membership,
      ),
    );
    multiAuthNotifier.updateAccount(me);
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

  Future<void> refreshSticker({bool force = false}) async {
    final refreshStickerLastTime =
        AccountKeyValue.instance.refreshStickerLastTime;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - refreshStickerLastTime < hours24) {
      return;
    }

    final res = await client.accountApi.getStickerAlbums();
    final albums = res.data..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final localLatestCreatedAt = await database.stickerAlbumDao
        .latestCreatedAt()
        .getSingleOrNull();

    var hasNewAlbum = false;
    if (localLatestCreatedAt == null && albums.isNotEmpty) {
      hasNewAlbum = true;
    }

    var maxOrder =
        await database.stickerAlbumDao.maxOrder().getSingleOrNull() ?? 0;

    for (final a in albums) {
      final localAlbum = await database.stickerAlbumDao
          .album(a.albumId)
          .getSingleOrNull();
      if (localAlbum == null) {
        maxOrder++;
      }
      await database.stickerAlbumDao.insert(
        a.asStickerAlbumsCompanion.copyWith(
          orderedAt: Value(localAlbum?.orderedAt ?? maxOrder),
          added: Value(localAlbum?.added ?? a.banner?.isNotEmpty == true),
        ),
      );

      hasNewAlbum =
          !hasNewAlbum &&
          localLatestCreatedAt != null &&
          a.createdAt.difference(localLatestCreatedAt).inSeconds > 1;

      await updateStickerAlbums(a.albumId);
    }

    if (hasNewAlbum) {
      AccountKeyValue.instance.hasNewAlbum = true;
    }

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
      await database.circleDao.insertUpdate(
        db.Circle(
          circleId: circle.circleId,
          name: circle.name,
          createdAt: circle.createdAt,
        ),
      );
      await handleCircle(circle);
    });

    AccountKeyValue.instance.hasSyncCircle = true;
  }

  Future<void> _cleanupQuoteContent() async {
    final clean = AccountKeyValue.instance.alreadyCleanupQuoteContent;
    if (clean) {
      return;
    }
    await database.jobDao.insert(createCleanupQuoteContentJob());
    AccountKeyValue.instance.alreadyCleanupQuoteContent = true;
  }

  Future<void> checkMigration() async {
    await _cleanupQuoteContent();
  }

  Future<void> handleCircle(CircleResponse circle, {int? offset}) async {
    final ccList = (await client.circleApi.getCircleConversations(
      circle.circleId,
    )).data;
    for (final cc in ccList) {
      await database.circleConversationDao.insert(
        db.CircleConversation(
          conversationId: cc.conversationId,
          circleId: cc.circleId,
          createdAt: cc.createdAt,
        ),
      );
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

  Future<void> updateStickerAlbums(String albumId) async {
    try {
      final response = await client.accountApi.getStickersByAlbumId(albumId);
      final relationships = <db.StickerRelationship>[];
      final stickers = <db.StickersCompanion>[];
      response.data.forEach((sticker) {
        relationships.add(
          db.StickerRelationship(
            albumId: albumId,
            stickerId: sticker.stickerId,
          ),
        );
        stickers.add(
          sticker.asStickersCompanion.copyWith(albumId: Value(albumId)),
        );
      });

      await database.mixinDatabase.transaction(() async {
        await database.stickerRelationshipDao.insertAll(relationships);
        await database.stickerDao.insertAll(stickers);
      });
    } catch (e, s) {
      w('Update sticker albums error: $e, stack: $s');
    }
  }

  Future<void> downloadAttachment(String messageId) async =>
      attachmentUtil.downloadAttachment(messageId: messageId);

  Future<void> reUploadGiphyGif(db.MessageItem message) {
    assert(
      message.type.isImage &&
          message.mediaMimeType == 'image/gif' &&
          (message.mediaSize == null || message.mediaSize == 0),
      'Invalid message',
    );
    return _sendMessageHelper.reUploadGiphyGif(message);
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

  Future<void> reUploadTranscriptAttachment(String messageId) =>
      _sendMessageHelper.reUploadTranscriptAttachment(messageId);

  Future<void> addUser(String userId, String? fullName) => _relationship(
    RelationshipRequest(
      userId: userId,
      action: RelationshipAction.add,
      fullName: fullName,
    ),
  );

  Future<void> removeUser(String userId) => _relationship(
    RelationshipRequest(userId: userId, action: RelationshipAction.remove),
  );

  Future<void> blockUser(String userId) => _relationship(
    RelationshipRequest(userId: userId, action: RelationshipAction.block),
  );

  Future<void> unblockUser(String userId) => _relationship(
    RelationshipRequest(userId: userId, action: RelationshipAction.unblock),
  );

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
    final randomId = const Uuid().v4();
    final conversationId = groupConversationId(
      userId,
      name.trim(),
      userIds,
      randomId,
    );

    final response = await client.conversationApi.createConversation(
      ConversationRequest(
        conversationId: conversationId,
        category: ConversationCategory.group,
        name: name.trim(),
        participants: userIds
            .map((e) => ParticipantRequest(userId: e))
            .toList(),
        randomId: randomId,
      ),
    );
    await database.conversationDao.updateConversation(response.data, userId);
    await addParticipant(conversationId, userIds);
  }

  Future<void> exitGroup(String conversationId) async {
    await client.conversationApi.exit(conversationId);
    await refreshConversation(conversationId);
  }

  Future<void> joinGroup(String code) async {
    final response = await client.conversationApi.join(code);
    await database.conversationDao.updateConversation(response.data, userId);
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

      await database.conversationDao.updateConversation(response.data, userId);
    } catch (e) {
      w('addParticipant error $e');
      // throw error??
    }
  }

  Future<void> removeParticipant(String conversationId, String userId) async {
    try {
      await client.conversationApi.participants(conversationId, 'REMOVE', [
        ParticipantRequest(userId: userId),
      ]);
    } catch (e) {
      w('removeParticipant error $e');
      rethrow;
    }
  }

  Future<void> updateParticipantRole(
    String conversationId,
    String userId,
    ParticipantRole? role,
  ) async {
    try {
      await client.conversationApi.participants(conversationId, 'ROLE', [
        ParticipantRequest(userId: userId, role: role),
      ]);
    } catch (e) {
      w('updateParticipantRole error $e');
      rethrow;
    }
  }

  Future<void> createCircle(
    String name,
    List<CircleConversationRequest> list,
  ) async {
    final response = await client.circleApi.createCircle(
      CircleName(name: name),
    );

    await database.circleDao.insertUpdate(
      db.Circle(
        circleId: response.data.circleId,
        name: response.data.name,
        createdAt: response.data.createdAt,
      ),
    );

    await editCircleConversation(response.data.circleId, list);
  }

  Future<void> updateCircle(String circleId, String name) async {
    final response = await client.circleApi.updateCircle(
      circleId,
      CircleName(name: name),
    );
    await database.circleDao.insertUpdate(
      db.Circle(
        circleId: response.data.circleId,
        name: response.data.name,
        createdAt: response.data.createdAt,
      ),
    );
  }

  Future<String> _initConversation(String? cid, String? recipientId) async {
    if (recipientId != null) {
      final conversationId = generateConversationId(recipientId, userId);
      if (cid != null) {
        assert(
          cid == conversationId,
          'cid: $cid != conversationId: $conversationId',
        );
      }
      final conversation = await database.conversationDao
          .conversationById(conversationId)
          .getSingleOrNull();
      if (conversation == null) {
        await database.conversationDao.insert(
          db.Conversation(
            conversationId: conversationId,
            category: ConversationCategory.contact,
            createdAt: DateTime.now(),
            ownerId: recipientId,
            status: ConversationStatus.start,
          ),
        );
        await database.participantDao.insert(
          db.Participant(
            conversationId: conversationId,
            userId: userId,
            createdAt: DateTime.now(),
          ),
        );
        await database.participantDao.insert(
          db.Participant(
            conversationId: conversationId,
            userId: recipientId,
            createdAt: DateTime.now(),
          ),
        );
      }
      return conversationId;
    } else if (cid != null) {
      return cid;
    } else {
      throw Exception('Parameter error');
    }
  }

  Future<void> editContactName(String userId, String name) => _relationship(
    RelationshipRequest(
      userId: userId,
      fullName: name,
      action: RelationshipAction.update,
    ),
  );

  Future<void> circleRemoveConversation(
    String circleId,
    String conversationId,
  ) async {
    await client.circleApi.updateCircleConversations(circleId, [
      CircleConversationRequest(
        action: CircleConversationAction.remove,
        conversationId: conversationId,
        userId: userId,
      ),
    ]);
    await database.circleConversationDao.deleteById(conversationId, circleId);
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
    await database.transaction(
      () => Future.wait(
        response.data.map((cc) async {
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
        }),
      ),
    );
  }

  Future<void> deleteCircle(String circleId) async {
    try {
      await client.circleApi.deleteCircle(circleId);
    } catch (e) {
      if (e is! MixinApiError || (e.error! as MixinError).code != notFound) {
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
      RelationshipRequest(userId: userId, action: RelationshipAction.block),
    );
    await database.userDao.insertSdkUser(response.data);
  }

  Future<void> unMuteConversation({
    String? conversationId,
    String? userId,
  }) async {
    await _mute(0, conversationId: conversationId, userId: userId);
  }

  Future<void> muteConversation(
    int duration, {
    String? conversationId,
    String? userId,
  }) async {
    await _mute(duration, conversationId: conversationId, userId: userId);
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
        await database.conversationDao.updateMuteUntil(
          conversationId,
          cr.muteUntil,
        );
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

    await database.conversationDao.updateConversation(response.data, userId);
  }

  Future<void> rotate(String conversationId) async {
    final response = await client.conversationApi.rotate(conversationId);
    await database.conversationDao.updateCodeUrl(
      conversationId,
      response.data.codeUrl,
    );
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
        (() async => addSessionAckJob([
          await createMentionReadAckJob(conversationId, messageId),
        ]))(),
      ]);

  Future<List<db.User>?> refreshUsers(List<String> ids, {bool force = false}) =>
      _injector.refreshUsers(ids, force: force);

  Future<void> refreshConversation(
    String conversationId, {
    bool checkCurrentUserExist = false,
  }) => _injector.refreshConversation(
    conversationId,
    checkCurrentUserExist: checkCurrentUserExist,
  );

  Future<void> updateAccount({String? fullName, String? biography}) async {
    final user = await client.accountApi.update(
      AccountUpdateRequest(fullName: fullName, biography: biography),
    );
    multiAuthNotifier.updateAccount(user.data);
  }

  Future<bool> cancelProgressAttachmentJob(String messageId) =>
      attachmentUtil.cancelProgressAttachmentJob(messageId);

  Future<void> _deleteMessageAttachment(db.Message message) async {
    if (message.category.isAttachment) {
      final path = attachmentUtil.convertAbsolutePath(
        category: message.category,
        conversationId: message.conversationId,
        fileName: message.mediaUrl,
      );
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } else if (message.category.isTranscript) {
      final iterable = await database.transcriptMessageDao
          .transcriptMessageByTranscriptId(message.messageId)
          .get();

      final list = await database.transcriptMessageDao
          .messageIdsByMessageIds(iterable.map((e) => e.messageId))
          .get();
      iterable.where((element) => !list.contains(element.messageId)).forEach((
        e,
      ) {
        final path = attachmentUtil.convertAbsolutePath(
          fileName: e.mediaUrl,
          messageId: e.messageId,
          isTranscript: true,
        );

        final file = File(path);
        if (file.existsSync()) unawaited(file.delete());
      });
    }
  }

  Future<void> _deleteMessageAttachmentByConversationId(
    String conversationId,
  ) async {
    final directories = [
      attachmentUtil.getImagesPath(conversationId),
      attachmentUtil.getVideosPath(conversationId),
      attachmentUtil.getAudiosPath(conversationId),
      attachmentUtil.getFilesPath(conversationId),
    ];

    await Future.wait(
      directories.map((dir) async {
        final directory = Directory(dir);
        if (!directory.existsSync()) return;
        await directory.delete(recursive: true);
      }),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final message = await database.messageDao.findMessageByMessageId(messageId);
    if (message == null) return;
    await attachmentUtil.cancelProgressAttachmentJob(messageId);
    await database.messageDao.deleteMessage(message.conversationId, messageId);
    unawaited(database.ftsDatabase.deleteByMessageId(messageId));
    unawaited(_deleteMessageAttachment(message));
  }

  Future<void> deleteMessagesByConversationId(String conversationId) async {
    final miniMessageIds = await database.messageDao
        .miniMessageByIds(attachmentUtil.downloadingIds.toList())
        .get();
    await Future.forEach(
      miniMessageIds.where(
        (message) => message.conversationId == conversationId,
      ),
      (message) =>
          attachmentUtil.cancelProgressAttachmentJob(message.messageId),
    );

    await database.messageDao.deleteMessagesByConversationId(conversationId);
    await database.messageMentionDao.clearMessageMentionByConversationId(
      conversationId,
    );
    unawaited(database.ftsDatabase.deleteByConversationId(conversationId));
    unawaited(_deleteMessageAttachmentByConversationId(conversationId));
  }

  String convertAbsolutePath(
    String category,
    String conversationId,
    String? fileName, [
    bool isTranscript = false,
  ]) => attachmentUtil.convertAbsolutePath(
    category: category,
    conversationId: conversationId,
    fileName: fileName,
    isTranscript: isTranscript,
  );

  String convertMessageAbsolutePath(
    db.MessageItem? messageItem, [
    bool isTranscript = false,
  ]) {
    if (messageItem == null) return '';
    return convertAbsolutePath(
      messageItem.type,
      messageItem.conversationId,
      messageItem.mediaUrl,
      isTranscript,
    );
  }

  Future<List<db.User>?> updateUserByIdentityNumber(String identityNumber) =>
      _injector.updateUserByIdentityNumber(identityNumber);

  Future<void> pinMessage({
    required String conversationId,
    required List<PinMessageMinimal> pinMessageMinimals,
  }) => _sendMessageHelper.sendPinMessage(
    conversationId: conversationId,
    senderId: userId,
    pinMessageMinimals: pinMessageMinimals,
    pin: true,
  );

  Future<void> unpinMessage({
    required String conversationId,
    required List<PinMessageMinimal> pinMessageMinimals,
  }) => _sendMessageHelper.sendPinMessage(
    conversationId: conversationId,
    senderId: userId,
    pinMessageMinimals: pinMessageMinimals,
    pin: false,
  );

  Future<void> updateSnapshotById({required String snapshotId}) async {
    final data = await client.snapshotApi.getSnapshotById(snapshotId);
    await database.snapshotDao.insertSdkSnapshot(data.data);
  }

  Future<void> updateSafeSnapshotById({required String snapshotId}) async {
    final data = await client.tokenApi.getSnapshotById(snapshotId);
    await database.safeSnapshotDao.insertSdkSnapshot(data.data);
  }

  Future<Snapshot> updateSnapshotByTraceId({required String traceId}) async {
    final data = await client.snapshotApi.getSnapshotByTraceId(traceId);
    final snapshot = data.data;
    await database.snapshotDao.insertSdkSnapshot(snapshot);
    return snapshot;
  }

  void updateAssetById({required String assetId}) =>
      addUpdateAssetJob(createUpdateAssetJob(assetId));

  void updateTokenById({required String assetId}) =>
      addUpdateTokenJob(createUpdateTokenJob(assetId));

  Future<AssetItem?> checkAsset({
    required String assetId,
    bool force = false,
  }) async {
    final asset = await database.assetDao.findAssetById(assetId);
    if (force || asset == null) {
      try {
        final a = (await client.assetApi.getAssetById(assetId)).data;
        final chain = (await client.assetApi.getChain(a.chainId)).data;

        await Future.wait([
          database.assetDao.insertSdkAsset(a),
          database.chainDao.insertSdkChain(chain),
        ]);
      } catch (error, stacktrace) {
        e('checkAsset: $error $stacktrace');
      }
    } else {
      final chain = await database.chainDao
          .chain(asset.chainId)
          .getSingleOrNull();
      if (chain == null) {
        await checkAsset(assetId: assetId, force: true);
      }
    }
    return database.assetDao.assetItem(assetId).getSingleOrNull();
  }

  Future<void> updateFiats() async {
    final data = await client.accountApi.getFiats();
    await database.fiatDao.insertAllSdkFiat(data.data);
  }

  Future<db.App?> findOrSyncApp(String id) async =>
      getAppAndCheckUser(id, null);

  Future<db.App?> getAppAndCheckUser(String id, DateTime? updatedAt) async {
    final app = await database.appDao.findAppById(id);

    if (app != null) {
      if (updatedAt == null) {
        return app;
      } else if (app.updatedAt == updatedAt) {
        return app;
      }
    }

    try {
      final user = await client.userApi.getUserById(id);
      await _injector.insertUpdateUsers([user.data]);
      return database.appDao.findAppById(id);
    } catch (error, stackTrace) {
      d('get app and check user error: $error, $stackTrace');
      return null;
    }
  }

  Future<void> loadFavoriteApps(String userId) async {
    final result = await client.userApi.getUserFavoriteApps(userId);
    final apps = result.data;
    await database.favoriteAppDao.insertFavoriteApps(userId, apps);

    // refresh app not exist.
    final appIds = apps.map((e) => e.appId).toList();

    final notExits = <String>[];
    for (final appId in appIds) {
      final needLoad =
          await database.appDao.findAppById(appId) == null ||
          await database.userDao.userById(appId).getSingleOrNull() == null;
      if (needLoad) {
        notExits.add(appId);
      }
    }
    if (notExits.isEmpty) {
      return;
    }
    final usersResponse = await client.userApi.getUsers(notExits);
    await _injector.insertUpdateUsers(usersResponse.data);
  }

  void _sendEventToWorkerIsolate(MainIsolateEventType type, [dynamic args]) {
    try {
      if (_isolateChannel == null) {
        d('_sendEventToWorkerIsolate: _isolateChannel is null $type');
        assert(type == MainIsolateEventType.exit);
      }
      _isolateChannel?.sink.add(type.toEvent(args));
    } catch (error, s) {
      e('_sendEventToWorkerIsolate: $error, $s');
    }
  }
}
