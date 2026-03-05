import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:ansicolor/ansicolor.dart';
import 'package:dio/dio.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:rhttp/rhttp.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../blaze/blaze.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/database.dart';
import '../db/database_event_bus.dart';
import '../db/fts_database.dart';
import '../db/mixin_database.dart' hide Chain;
import '../runtime/db_write/method.dart';
import '../runtime/db_write/payload.dart';
import '../runtime/isolate/protocol.dart';
import '../runtime/isolate/router.dart';
import '../runtime/isolate/rpc_client.dart';
import '../runtime/sync/tick_patch_batcher.dart';
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/logger.dart';
import '../utils/mixin_api_client.dart';
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
import 'job/sync_inscription_message_job.dart';
import 'job/update_asset_job.dart';
import 'job/update_sticker_job.dart';
import 'job/update_token_job.dart';
import 'sender.dart';

const _kWorkerDbWriteRpcPrefix = 'db_write:';

class SyncWorkerInitParams {
  SyncWorkerInitParams({
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

Future<void> startSyncWorkerIsolate(SyncWorkerInitParams params) async {
  EquatableConfig.stringify = true;
  ansiColorDisabled = Platform.isIOS;
  mixinDocumentsDirectory = Directory(params.mixinDocumentDirectory);
  await Rhttp.init();
  BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);
  final isolateChannel = IsolateChannel<dynamic>.connectSend(
    params.sendPort,
  );
  final router = IsolateRouter.worker(
    inbound: isolateChannel.stream,
    sendMessage: isolateChannel.sink.add,
  );
  final rpcClient = IsolateRpcClient(router);
  final runner = _SyncWorkerRunner(
    identityNumber: params.identityNumber,
    userId: params.userId,
    sessionId: params.sessionId,
    privateKeyStr: params.privateKey,
    primarySessionId: params.primarySessionId,
    emitEvent: router.sendEvent,
    sendPort: params.sendPort,
    rpcClient: rpcClient,
  );
  router.commands.listen((command) {
    try {
      runner.onCommand(command);
    } catch (error, stacktrace) {
      e('error: $error, stacktrace: $stacktrace');
    }
  });
  await runner.init(params);
  runner._start();
  router
    ..sendReady()
    ..sendEvent(const WorkerIsolateReadyEvent());
}

final Map<String, MessageStatus> pendingMessageStatusMap = {};

class _SyncWorkerRunner {
  _SyncWorkerRunner({
    required this.identityNumber,
    required this.userId,
    required this.sessionId,
    required this.privateKeyStr,
    required this.primarySessionId,
    required this.emitEvent,
    required this.sendPort,
    required this.rpcClient,
  }) : privateKey = ed.PrivateKey(base64Decode(privateKeyStr));

  final String identityNumber;
  final String userId;
  final String sessionId;
  final String privateKeyStr;
  final ed.PrivateKey privateKey;
  final String? primarySessionId;
  final SendPort sendPort;
  final IsolateRpcClient rpcClient;

  final void Function(WorkerEvent event) emitEvent;
  late final TickPatchBatcher _syncPatchBatcher = TickPatchBatcher(
    onFlush: (patches) =>
        _sendEventToMainIsolate(WorkerSyncPatchesEvent(patches: patches)),
  );

  DecryptMessage? _decryptMessage;

  late Client client;
  late Database database;
  late Blaze blaze;
  late Sender _sender;
  late SignalProtocol signalProtocol;

  late SendingJob _sendingJob;
  late AckJob _ackJob;
  late UpdateAssetJob _updateAssetJob;
  late UpdateStickerJob _updateStickerJob;
  late UpdateTokenJob _updateTokenJob;
  late SessionAckJob _sessionAckJob;
  late SyncInscriptionMessageJob _syncInscriptionMessageJob;
  late FloodJob _floodJob;
  DeviceTransferIsolateController? _deviceTransfer;

  final jobSubscribers = <StreamSubscription>[];

  Timer? _nextExpiredMessageRunner;

  Future<void> init(SyncWorkerInitParams initParams) async {
    DataBaseEventBus.instance.legacyEventBridgeEnabled = false;
    database = Database(
      await connectToDatabase(identityNumber),
      await FtsDatabase.connect(identityNumber),
    );

    client = createClient(
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKeyStr,
      interceptors: [
        InterceptorsWrapper(
          onError: (e, handler) async {
            _sendEventToMainIsolate(WorkerApiRequestedErrorEvent(error: e));
            handler.next(e);
          },
        ),
      ],
      loginByPhoneNumber: initParams.loginByPhoneNumber,
    )..configProxySetting(database.settingProperties);

    _ackJob = AckJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      client: client,
    );

    _floodJob = FloodJob(
      database: database,
      requestDbWrite: _requestDbWrite,
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
      _requestDbWrite,
    );

    blaze.connectedStateStream.listen((event) {
      _sendEventToMainIsolate(
        WorkerBlazeConnectStateChangedEvent(state: event),
      );
    });

    signalProtocol = SignalProtocol(userId)..init();

    _sender = Sender(
      signalProtocol,
      blaze,
      client,
      sessionId,
      userId,
      database,
      _requestDbWrite,
    );

    _sendingJob = SendingJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      sender: _sender,
      userId: userId,
      sessionId: sessionId,
      privateKey: privateKey,
      signalProtocol: signalProtocol,
    );

    _sessionAckJob = SessionAckJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      userId: userId,
      primarySessionId: primarySessionId,
      sender: _sender,
    );
    _updateAssetJob = UpdateAssetJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      client: client,
    );
    _updateTokenJob = UpdateTokenJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      client: client,
    );

    _updateStickerJob = UpdateStickerJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      client: client,
    );
    _syncInscriptionMessageJob = SyncInscriptionMessageJob(
      database: database,
      requestDbWrite: _requestDbWrite,
      client: client,
    );

    MigrateFtsJob(database: database, requestDbWrite: _requestDbWrite);
    DeleteOldFtsRecordJob(database: database, requestDbWrite: _requestDbWrite);
    CleanupQuoteContentJob(database: database, requestDbWrite: _requestDbWrite);

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
      e(
        'device_transfer: primarySessionId is null, device transfer is disabled',
      );
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
      _syncInscriptionMessageJob,
      _requestDbWrite,
    );

    jobSubscribers.add(
      DataBaseEventBus.instance.patchStream.listen((event) {
        _syncPatchBatcher.add(event);
      }),
    );
    _floodJob.start();
  }

  Function(FloodMessage floodMessage)? getProcessFloodJob() =>
      _decryptMessage?.process;

  void _start() {
    blaze.connect();

    jobSubscribers
      ..add(
        blaze.connectedStateStream
            .where((state) => state == ConnectedState.connected)
            .listen((event) {
              _floodJob.start();
            }),
      )
      ..add(
        DataBaseEventBus.instance.updateExpiredMessageTableStream
            .startWith(null)
            .asyncBufferMap((event) => _scheduleExpiredJob())
            .listen((_) {}),
      );
  }

  void _sendEventToMainIsolate(WorkerEvent event) => emitEvent(event);

  Future<void> _requestDbWrite(
    DbWriteMethod method, {
    Object? payload,
  }) async {
    await rpcClient.request(
      '$_kWorkerDbWriteRpcPrefix${method.name}',
      payload: payload,
      timeout: const Duration(seconds: 20),
    );
  }

  Future<void> _scheduleExpiredJob() async {
    d('_scheduleExpiredJob');
    final messages = await database.expiredMessageDao
        .getCurrentExpiredMessages();
    if (messages.isEmpty) return;

    for (final em in messages) {
      // cancel attachment download.
      final message = await database.messageDao.findMessageByMessageId(
        em.messageId,
      );
      if (message == null) {
        e('message is null, messageId: ${em.messageId} ${em.expireAt}');
        await _requestDbWrite(
          DbWriteMethod.deleteExpiredMessageByMessageId,
          payload: em.messageId,
        );
        continue;
      }
      await _requestDbWrite(
        DbWriteMethod.deleteMessage,
        payload: DbWriteDeleteMessagePayload(
          conversationId: message.conversationId,
          messageId: em.messageId,
        ),
      );
      unawaited(
        _requestDbWrite(
          DbWriteMethod.deleteFtsByMessageId,
          payload: em.messageId,
        ),
      );
      if (message.category.isAttachment || message.category.isTranscript) {
        _sendEventToMainIsolate(
          WorkerRequestDownloadAttachmentEvent(
            request: AttachmentDeleteRequest(message: message),
          ),
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
        seconds:
            firstExpiredMessage.expireAt! -
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      _scheduleExpiredJob,
    );
  }

  void onCommand(WorkerCommand command) {
    switch (command) {
      case UpdateSelectedConversationCommand(:final conversationId):
        _decryptMessage?.conversationId = conversationId;
      case DisconnectBlazeWithTimeCommand():
        blaze.waitSyncTime();
      case ReconnectBlazeCommand():
        i('sync worker isolate: reconnect blaze');
        blaze.reconnect();
      case AddAckJobsCommand(:final jobs):
        _ackJob.add(jobs);
      case AddSessionAckJobsCommand(:final jobs):
        _sessionAckJob.add(jobs);
      case AddSendingJobCommand(:final job):
        _sendingJob.add(job);
      case AddUpdateAssetJobCommand(:final job):
        _updateAssetJob.add(job);
      case AddUpdateTokenJobCommand(:final job):
        _updateTokenJob.add(job);
      case AddUpdateStickerJobCommand(:final job):
        _updateStickerJob.add(job);
      case AddSyncInscriptionMessageJobCommand(:final job):
        _syncInscriptionMessageJob.add(job);
      case ExitWorkerCommand():
        dispose();
        Isolate.exit();
    }
  }

  void dispose() {
    _syncPatchBatcher.dispose();
    blaze.dispose();
    database.dispose();
    unawaited(rpcClient.dispose());
    jobSubscribers.forEach((subscription) => subscription.cancel());
    _deviceTransfer?.dispose();
  }
}
