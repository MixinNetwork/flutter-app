import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:ansicolor/ansicolor.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:ed25519_edwards/ed25519_edwards.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:stream_channel/isolate_channel.dart';

import '../blaze/blaze.dart';
import '../crypto/signal/signal_protocol.dart';
import '../db/database.dart';
import '../db/extension/message.dart';
import '../db/mixin_database.dart' as db;
import '../db/mixin_database.dart' hide Chain;
import '../utils/extension/extension.dart';
import '../utils/file.dart';
import '../utils/logger.dart';
import '../utils/mixin_api_client.dart';
import '../utils/system/package_info.dart';
import 'decrypt_message.dart';
import 'isolate_event.dart';
import 'job/ack_job.dart';
import 'job/flood_job.dart';
import 'job/sending_job.dart';
import 'job/session_ack_job.dart';
import 'job/update_asset_job.dart';
import 'job/update_sticker_job.dart';
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

  late SendingJob _sendingJob;
  late AckJob _ackJob;
  late UpdateAssetJob _updateAssetJob;
  late UpdateStickerJob _updateStickerJob;
  late SessionAckJob _sessionAckJob;
  late FloodJob _floodJob;

  final jobSubscribers = <StreamSubscription>[];

  Timer? _nextExpiredMessageRunner;

  Future<void> init(IsolateInitParams initParams) async {
    database = Database(await connectToDatabase(identityNumber, readCount: 4));

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
      loginByPhoneNumber: initParams.loginByPhoneNumber,
    );

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
    );

    blaze.connectedStateStream.listen((event) {
      _sendEventToMainIsolate(
          WorkerIsolateEventType.onBlazeConnectStateChanged, event);
    });

    signalProtocol = SignalProtocol(userId)..init();

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

    _updateAssetJob = UpdateAssetJob(
      database: database,
      client: client,
    );

    _updateStickerJob = UpdateStickerJob(
      database: database,
      client: client,
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
      _ackJob,
      _sendingJob,
      _updateStickerJob,
      _updateAssetJob,
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
      ..add(DataBaseEventBus.instance
          .watchEvent(DatabaseEvent.updateExpiredMessageTable)
          .asyncDropListen((event) => _scheduleExpiredJob()));
    _scheduleExpiredJob();
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
        await database.messageDao
            .deleteMessage(message.conversationId, em.messageId);
        if (message.category.isAttachment || message.category.isTranscript) {
          _sendEventToMainIsolate(
            WorkerIsolateEventType.requestDownloadAttachment,
            AttachmentDeleteRequest(message: message),
          );
        }
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
        blaze.reconnect();
        break;
      case MainIsolateEventType.addAckJob:
        _ackJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.addSessionAckJob:
        _sessionAckJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.addSendingJob:
        _sendingJob.add(event.argument as Job);
        break;
      case MainIsolateEventType.addUpdateAssetJob:
        _updateAssetJob.add(event.argument as Job);
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
    jobSubscribers.forEach((subscription) => subscription.cancel());
  }
}
