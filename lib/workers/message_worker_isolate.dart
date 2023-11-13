import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:ansicolor/ansicolor.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../blaze/blaze.dart';
import '../crypto/signal/signal_database.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/app/app_database.dart';
import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../db/fts_database.dart';
import '../db/mixin_database.dart' hide Chain;
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/logger.dart';
import '../utils/mixin_api_client.dart';
import '../utils/proxy.dart';
import '../utils/system/package_info.dart';
import 'decrypt_message.dart';
import 'device_transfer.dart';
import 'isolate_event.dart';
import 'job/ack_job.dart';
import 'job/cleanup_quote_content_job.dart';
import 'job/delete_old_fts_record_job.dart';
import 'job/flood_job.dart';
import 'job/migrate_fts_job.dart';
import 'job/sending_job.dart';
import 'job/session_ack_job.dart';
import 'job/update_asset_job.dart';
import 'job/update_sticker_job.dart';
import 'job/update_token_job.dart';
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
    required this.loginByPhoneNumber,
    required this.rootIsolateToken,
  });

  final SendPort sendPort;
  final String identityNumber;
  final String userId;
  final String sessionId;
  final String privateKey;
  final String mixinDocumentDirectory;
  final String? primarySessionId;

  final bool loginByPhoneNumber;
  final ui.RootIsolateToken rootIsolateToken;
}

Future<void> startMessageProcessIsolate(IsolateInitParams params) async {
  EquatableConfig.stringify = true;
  ansiColorDisabled = Platform.isIOS;
  mixinDocumentsDirectory = Directory(params.mixinDocumentDirectory);
  BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);
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

  DecryptMessage? _decryptMessage;

  late Client client;
  late Database database;
  late Blaze blaze;
  late Sender _sender;
  late SignalProtocol signalProtocol;
  late AppDatabase appDatabase;

  late SendingJob _sendingJob;
  late AckJob _ackJob;
  late UpdateAssetJob _updateAssetJob;
  late UpdateStickerJob _updateStickerJob;
  late UpdateTokenJob _updateTokenJob;
  late SessionAckJob _sessionAckJob;
  late FloodJob _floodJob;
  DeviceTransferIsolateController? _deviceTransfer;

  final jobSubscribers = <StreamSubscription>[];

  Timer? _nextExpiredMessageRunner;

  Future<void> init(IsolateInitParams initParams) async {
    appDatabase = AppDatabase.connect();

    database = Database(
      await connectToDatabase(identityNumber, readCount: 4),
      await FtsDatabase.connect(identityNumber),
    );

    final signalDb = await SignalDatabase.connect(
      identityNumber: identityNumber,
      openForLogin: false,
      fromMainIsolate: false,
    );

    client = createClient(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKeyStr,
      interceptors: [
        InterceptorsWrapper(
          onError: (
            DioException e,
            ErrorInterceptorHandler handler,
          ) async {
            _sendEventToMainIsolate(
                WorkerIsolateEventType.onApiRequestedError, e);
            handler.next(e);
          },
        ),
      ],
      loginByPhoneNumber: initParams.loginByPhoneNumber,
    )..configProxySetting(appDatabase.settingKeyValue);

    _ackJob = AckJob(
      database: database,
      client: client,
    );

    _floodJob = FloodJob(
      database: database,
      getProcessFloodJob: getProcessFloodJob,
    );

    blaze = Blaze(
      userId,
      sessionId,
      privateKeyStr,
      database,
      client,
      await generateUserAgent(),
      _ackJob,
      _floodJob,
      appDatabase.settingKeyValue,
    );

    blaze.connectedStateStream.listen((event) {
      _sendEventToMainIsolate(
          WorkerIsolateEventType.onBlazeConnectStateChanged, event);
    });

    signalProtocol = SignalProtocol(userId, signalDb)..init();

    _sender = Sender(
      signalProtocol,
      blaze,
      client,
      sessionId,
      userId,
      database,
    );

    _sendingJob = SendingJob(
      database: database,
      sender: _sender,
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
      signalProtocol: signalProtocol,
    );

    _sessionAckJob = SessionAckJob(
      database: database,
      userId: userId,
      primarySessionId: primarySessionId,
      sender: _sender,
    );
    _updateAssetJob = UpdateAssetJob(database: database, client: client);
    _updateTokenJob = UpdateTokenJob(database: database, client: client);

    _updateStickerJob = UpdateStickerJob(database: database, client: client);

    MigrateFtsJob(database: database);
    DeleteOldFtsRecordJob(database: database);
    CleanupQuoteContentJob(database: database);

    if (primarySessionId != null) {
      _deviceTransfer = await startTransferIsolate(
        userId: userId,
        messageDeliver: (message) async {
          d('device_transfer: send message: $message');
          final result = await _sender.deliver(message);
          if (!result.success) {
            w('device_transfer: send message failed: $result');
          } else {
            d('device_transfer: send message success: $result');
          }
        },
        primarySessionId: primarySessionId!,
        identityNumber: identityNumber,
        rootIsolateToken: initParams.rootIsolateToken,
        mixinDocumentDirectory: initParams.mixinDocumentDirectory,
      );
    } else {
      e('device_transfer: primarySessionId is null, device transfer is disabled');
    }

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
      _ackJob,
      _sendingJob,
      _updateStickerJob,
      _updateAssetJob,
      _deviceTransfer,
      _updateTokenJob,
      signalDb,
    );
    _floodJob.start();
  }

  Function(FloodMessage floodMessage)? getProcessFloodJob() =>
      _decryptMessage?.process;

  void _start() {
    blaze.connect();

    jobSubscribers
      ..add(blaze.connectedStateStream
          .where((state) => state == ConnectedState.connected)
          .listen((event) {
        _floodJob.start();
      }))
      ..add(DataBaseEventBus.instance.updateExpiredMessageTableStream
          .startWith(null)
          .asyncBufferMap((event) => _scheduleExpiredJob())
          .listen((_) {}));
  }

  void _sendEventToMainIsolate(WorkerIsolateEventType event,
      [dynamic argument]) {
    eventSink.add(event.toEvent(argument));
  }

  Future<void> _scheduleExpiredJob() async {
    d('_scheduleExpiredJob');
    final messages =
        await database.expiredMessageDao.getCurrentExpiredMessages();
    if (messages.isEmpty) return;

    for (final em in messages) {
      // cancel attachment download.
      final message =
          await database.messageDao.findMessageByMessageId(em.messageId);
      if (message == null) {
        e('message is null, messageId: ${em.messageId} ${em.expireAt}');
        await database.expiredMessageDao.deleteByMessageId(em.messageId);
        continue;
      }
      await database.messageDao
          .deleteMessage(message.conversationId, em.messageId);
      unawaited(database.ftsDatabase.deleteByMessageId(em.messageId));
      if (message.category.isAttachment || message.category.isTranscript) {
        _sendEventToMainIsolate(
          WorkerIsolateEventType.requestDownloadAttachment,
          AttachmentDeleteRequest(message: message),
        );
      }
    }

    final firstExpiredMessage = await database.expiredMessageDao
        .getFirstExpiredMessage()
        .getSingleOrNull();
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

  void onEvent(MainIsolateEvent event) {
    switch (event.type) {
      case MainIsolateEventType.updateSelectedConversation:
        final conversationId = event.argument as String?;
        _decryptMessage?.conversationId = conversationId;
        break;
      case MainIsolateEventType.disconnectBlazeWithTime:
        blaze.waitSyncTime();
        break;
      case MainIsolateEventType.reconnectBlaze:
        i('message worker isolate: reconnect blaze');
        blaze.reconnect();
        break;
      case MainIsolateEventType.addAckJobs:
        _ackJob.add(event.argument as List<Job>);
        break;
      case MainIsolateEventType.addSessionAckJobs:
        _sessionAckJob.add(event.argument as List<Job>);
        break;
      case MainIsolateEventType.addSendingJob:
        _sendingJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.addUpdateAssetJob:
        _updateAssetJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.addUpdateTokenJob:
        _updateTokenJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.addUpdateStickerJob:
        _updateStickerJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.exit:
        dispose();
        Isolate.exit();
    }
  }

  void dispose() {
    blaze.dispose();
    database.dispose();
    appDatabase.close();
    jobSubscribers.forEach((subscription) => subscription.cancel());
    _deviceTransfer?.dispose();
  }
}
