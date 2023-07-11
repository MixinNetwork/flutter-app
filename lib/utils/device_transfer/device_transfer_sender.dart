import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../../constants/constants.dart';
import '../../db/database.dart';
import '../../enum/media_status.dart';
import '../attachment/attachment_util.dart';
import '../extension/extension.dart';
import '../logger.dart';
import 'cipher.dart';
import 'socket_wrapper.dart';
import 'speed_calculator.dart';
import 'transfer_data_app.dart';
import 'transfer_data_asset.dart';
import 'transfer_data_command.dart';
import 'transfer_data_conversation.dart';
import 'transfer_data_expired_message.dart';
import 'transfer_data_message.dart';
import 'transfer_data_participant.dart';
import 'transfer_data_pin_message.dart';
import 'transfer_data_snapshot.dart';
import 'transfer_data_sticker.dart';
import 'transfer_data_transcript_message.dart';
import 'transfer_data_user.dart';
import 'transfer_protocol.dart';

const _kQueryLimit = 100;

// progress: 0 - 100
typedef OnSendProgressUpdate = void Function(double progress);
typedef OnSendStart = void Function();
typedef OnSendSucceed = void Function();
typedef OnSendFailed = void Function();

typedef OnSendNetworkSpeedUpdate = void Function(double speed);

class DeviceTransferSender {
  DeviceTransferSender({
    required this.database,
    required this.attachmentUtil,
    required this.protocolTempFileDir,
    required this.deviceId,
    this.onSenderProgressUpdate,
    this.onSenderStart,
    this.onSenderSucceed,
    this.onSenderFailed,
    this.onSenderServerCreated,
    this.onSenderNetworkSpeedUpdate,
  });

  final Database database;
  final AttachmentUtilBase attachmentUtil;
  final String protocolTempFileDir;
  final OnSendProgressUpdate? onSenderProgressUpdate;
  final OnSendStart? onSenderStart;
  final OnSendSucceed? onSenderSucceed;
  final OnSendFailed? onSenderFailed;
  final OnSendStart? onSenderServerCreated;
  final OnSendNetworkSpeedUpdate? onSenderNetworkSpeedUpdate;
  final String deviceId;

  ServerSocket? _socket;

  TransferSocket? _clientSocket;
  final _speedCalculator = SpeedCalculator();

  final _pendingVerificationSockets = <Socket>[];

  var _debugStarting = false;

  var _finished = false;

  void resetTransferStates() {
    _finished = false;
    _speedCalculator.reset();
  }

  @visibleForTesting
  @mustCallSuper
  FutureOr<void> onPacketSend() {}

  void _notifyProgressUpdate(double progress) {
    onSenderProgressUpdate?.call(progress);
  }

  Future<(int port, TransferSecretKey key)> startServerSocket(
      int verificationCode) async {
    assert(!_debugStarting, 'server socket starting');
    if (_socket != null) {
      w('startServerSocket: already started');
      await close(debugReason: 'start need close current');
    }
    resetTransferStates();
    _debugStarting = true;
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _socket = serverSocket;
    _debugStarting = false;

    final transferKey = generateTransferKey();

    serverSocket.listen((socket) async {
      if (_clientSocket != null) {
        e('client already connected, close this connection');
        socket.destroy();
        return;
      }
      _pendingVerificationSockets.add(socket);

      final remoteHost = '${socket.remoteAddress.address}:${socket.remotePort}';
      i('client connected: $remoteHost');

      final transferSocket = TransferSocket(
        socket,
        transferKey,
        onWriteBytes: (size) {
          _speedCalculator.add(size);
          onSenderNetworkSpeedUpdate?.call(_speedCalculator.speed);
        },
      );
      Stream<TransferPacket>.eventTransformed(
        socket,
        (sink) => TransferProtocolSink(sink, protocolTempFileDir, transferKey),
      ).asyncListen((event) {
        d('receive data: $event');

        if (event is TransferCommandPacket) {
          final command = event.command;
          switch (command.action) {
            case kTransferCommandActionConnect:
              if (command.code == verificationCode) {
                i('sender verify code success. start transfer ${socket.remoteAddress.address}:${socket.remotePort}');
                _clientSocket = transferSocket;
                _pendingVerificationSockets.remove(socket);
                for (final s in _pendingVerificationSockets) {
                  s
                    ..close()
                    ..destroy();
                }
                _pendingVerificationSockets.clear();
                onSenderStart?.call();
                _processTransfer(transferSocket).onError((error, stacktrace) {
                  e('sender: process transfer error: $error $stacktrace');
                });
              } else {
                e('sender verify code failed. except $verificationCode, '
                    'but got ${command.code}');
                for (final s in _pendingVerificationSockets) {
                  s
                    ..close()
                    ..destroy();
                }
                _pendingVerificationSockets.clear();
                close(debugReason: 'verify code failed');
              }
              break;
            case kTransferCommandActionFinish:
              i('client finished. close connection');
              _finished = true;
              close();
              break;
            case kTransferCommandActionClose:
              w('client closed. close connection');
              close();
              break;
            case kTransferCommandActionProgress:
              final progress = command.progress!;
              i('remote progress command: progress $progress');
              _notifyProgressUpdate(progress);
              break;
          }
        }
      }, onDone: () {
        w('sender: client connected done. $remoteHost'
            ' isFinished: $_finished, verified: ${_clientSocket == transferSocket}');
        if (_clientSocket != null && _clientSocket != transferSocket) {
          w('connection done, but not the verified client. ignore.');
          return;
        }
        if (_clientSocket == null) {
          w('connection done, but current no verified client. ignore.');
          return;
        }
        close(debugReason: 'client connected done');
      }, onError: (error, stacktrace) {
        if (_clientSocket != null && _clientSocket != transferSocket) {
          i('connection error, but not the verified client. ignore.');
          return;
        }
        onSenderFailed?.call();
        e('sender: server socket error: $error $stacktrace');
        close(debugReason: 'socket error');
      });
    });
    onSenderServerCreated?.call();
    return (serverSocket.port, transferKey);
  }

  /// transfer data to client.
  Future<void> _processTransfer(TransferSocket socket) async {
    Future<void> runWithLog(
        Future<int> Function(TransferSocket) process, String name) async {
      final stopwatch = Stopwatch()..start();
      i('_processTransfer start $name');
      final count = await process(socket);
      i('_processTransfer end $name, count: $count cost: ${stopwatch.elapsed}');
    }

    // send total count
    await runWithLog((socket) async {
      final db = database.mixinDatabase;
      final count = await db.messageDao.countMediaMessages().getSingle() +
          await db.messageDao.countMessages().getSingle() +
          await db.stickerDao.countStickers().getSingle() +
          await db.assetDao.countAssets().getSingle() +
          await db.snapshotDao.countSnapshots().getSingle() +
          await db.userDao.countUsers().getSingle() +
          await db.conversationDao.countConversations().getSingle() +
          await db.participantDao.countParticipants().getSingle() +
          await db.pinMessageDao.countPinMessages().getSingle() +
          await database.transcriptMessageDao
              .countTranscriptMessages()
              .getSingle() +
          await database.expiredMessageDao.countExpiredMessages().getSingle() +
          await database.messageMentionDao.getMessageMentionsCount() +
          await database.appDao.getAppsCount();
      await socket.addCommand(TransferDataCommand.start(
        deviceId: deviceId,
        total: count,
      ));
      return count;
    }, 'send_total_count');

    _notifyProgressUpdate(0);

    await runWithLog(_processTransferConversation, 'conversation');
    await runWithLog(_processTransferParticipant, 'participant');
    await runWithLog(_processTransferUser, 'user');
    await runWithLog(_processTransferApp, 'app');
    await runWithLog(_processTransferSticker, 'sticker');
    await runWithLog(_processTransferAsset, 'asset');
    await runWithLog(_processTransferSnapshot, 'snapshot');
    await runWithLog(_processTransferTranscriptMessage, 'transcriptMessage');
    await runWithLog(_processTransferPinMessage, 'pinMessage');
    await runWithLog(_processTransferMessage, 'message');
    await runWithLog(_processTransferMessageMention, 'messageMention');
    await runWithLog(_processTransferExpiredMessage, 'expiredMessage');

    await socket.addCommand(TransferDataCommand.simple(
      deviceId: deviceId,
      action: kTransferCommandActionFinish,
    ));
  }

  Future<int> _processTransferConversation(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final conversations = await database.conversationDao.getConversations(
        limit: _kQueryLimit,
        offset: offset,
      );
      offset += conversations.length;
      for (final conversation in conversations) {
        await socket.addConversation(
          TransferDataConversation.fromDbConversation(conversation),
        );
        await onPacketSend();
      }
      if (conversations.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferUser(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final users =
          await database.userDao.getUsers(limit: _kQueryLimit, offset: offset);
      offset += users.length;
      for (final user in users) {
        await socket.addUser(TransferDataUser.fromDbUser(user));
        await onPacketSend();
      }
      if (users.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferApp(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final apps =
          await database.appDao.getApps(limit: _kQueryLimit, offset: offset);
      offset += apps.length;
      for (final app in apps) {
        await socket.addApp(TransferDataApp.fromDbApp(app));
        await onPacketSend();
      }
      if (apps.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferParticipant(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final participants = await database.participantDao.getAllParticipants(
        limit: _kQueryLimit,
        offset: offset,
      );
      offset += participants.length;
      for (final participant in participants) {
        await socket.addParticipant(
          TransferDataParticipant.fromDbParticipant(participant),
        );
        await onPacketSend();
      }
      if (participants.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferSticker(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final stickers = await database.stickerDao.getStickers(
        limit: _kQueryLimit,
        offset: offset,
      );
      offset += stickers.length;
      for (final sticker in stickers) {
        await socket.addSticker(
          TransferDataSticker.fromDbSticker(sticker),
        );
        await onPacketSend();
      }
      if (stickers.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferAsset(TransferSocket socket) async {
    final assets = await database.assetDao.getAssets();
    for (final asset in assets) {
      await socket.addAsset(
        TransferDataAsset.fromDbAsset(asset),
      );
      await onPacketSend();
    }
    return assets.length;
  }

  Future<int> _processTransferSnapshot(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final snapshots = await database.snapshotDao.getSnapshots(
        limit: _kQueryLimit,
        offset: offset,
      );
      offset += snapshots.length;
      for (final snapshot in snapshots) {
        await socket.addSnapshot(
          TransferDataSnapshot.fromDbSnapshot(snapshot),
        );
        await onPacketSend();
      }
      if (snapshots.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferMessage(TransferSocket socket) async {
    // check cleanup_quote_content_job finished before transfer message
    while (true) {
      final jobs =
          await database.jobDao.jobByAction(kCleanupQuoteContent).get();
      if (jobs.isEmpty) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    var lastMessageRowId = -1;
    var count = 0;
    while (true) {
      final messages = await database.messageDao
          .getDeviceTransferMessages(lastMessageRowId, _kQueryLimit);
      if (messages.isEmpty) {
        break;
      }
      count += messages.length;
      lastMessageRowId = messages.last.$1;
      for (final (_, message) in messages) {
        await socket.addMessage(
          TransferDataMessage.fromDbMessage(message),
        );
        await onPacketSend();
        if (message.category.isAttachment) {
          if (message.mediaStatus == MediaStatus.done ||
              message.mediaStatus == MediaStatus.read) {
            final path = attachmentUtil.convertAbsolutePath(
              category: message.category,
              conversationId: message.conversationId,
              fileName: message.mediaUrl,
            );
            final exist = File(path).existsSync();
            if (exist) {
              await socket.addAttachment(message.messageId, path);
            } else {
              e('attachment not exist: $path');
            }
          } else {
            w('attachment not done/read: ${message.messageId} ${message.mediaStatus}');
          }
        }
      }
    }
    return count;
  }

  Future<int> _processTransferMessageMention(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final messages = await database.messageMentionDao
          .getMessageMentions(_kQueryLimit, offset);
      offset += messages.length;
      for (final message in messages) {
        await socket.addMessageMention(message);
        await onPacketSend();
      }
      if (messages.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferTranscriptMessage(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final messages =
          await database.transcriptMessageDao.getTranscriptMessages(
        limit: _kQueryLimit,
        offset: offset,
      );
      offset += messages.length;
      for (final message in messages) {
        await socket.addTranscriptMessage(
          TransferDataTranscriptMessage.fromDbTranscriptMessage(message),
        );
        await onPacketSend();
        if (message.category.isAttachment) {
          if (message.mediaStatus == MediaStatus.done) {
            final path = attachmentUtil.convertAbsolutePath(
              isTranscript: true,
              category: message.category,
              fileName: message.mediaUrl,
            );
            final exist = File(path).existsSync();
            if (exist) {
              await socket.addAttachment(message.messageId, path);
            } else {
              e('attachment not exist: $path');
            }
          } else {
            w('attachment not done: ${message.messageId} ${message.mediaStatus}');
          }
        }
      }
      if (messages.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferExpiredMessage(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final messages = await database.expiredMessageDao
          .getAllExpiredMessages(
            _kQueryLimit,
            offset,
          )
          .get();
      offset += messages.length;
      for (final message in messages) {
        await socket.addExpiredMessage(
          TransferDataExpiredMessage.fromDbExpiredMessage(message),
        );
        await onPacketSend();
      }
      if (messages.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferPinMessage(TransferSocket socket) async {
    var offset = 0;
    while (true) {
      final messages = await database.pinMessageDao.getPinMessages(
        limit: _kQueryLimit,
        offset: offset,
      );
      offset += messages.length;
      for (final message in messages) {
        await socket.addPinMessage(
          TransferDataPinMessage.fromDbPinMessage(message),
        );
        await onPacketSend();
      }
      if (messages.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<void> close({String? debugReason}) async {
    i('sender: closing transfer server. $debugReason');
    final socket = _socket;
    final clientSocket = _clientSocket;
    _socket = null;
    _clientSocket = null;

    if (socket == null && clientSocket == null) {
      return;
    }

    if (_finished) {
      onSenderSucceed?.call();
    } else {
      onSenderFailed?.call();
    }
    await clientSocket?.close();
    clientSocket?.destroy();
    await socket?.close();
    i('sender: transfer server closed');
  }
}
