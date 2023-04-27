import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

import '../../db/database.dart';
import '../attachment/attachment_util.dart';
import '../extension/extension.dart';
import '../logger.dart';
import '../platform.dart';
import 'json_transfer_data.dart';
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

class DeviceTransferSender {
  DeviceTransferSender({
    required this.database,
    required this.attachmentUtil,
    required this.protocolTransform,
    required this.deviceId,
    this.onSenderProgressUpdate,
    this.onSenderStart,
    this.onSenderSucceed,
    this.onSenderFailed,
    this.onSenderServerCreated,
  });

  final Database database;
  final AttachmentUtilBase attachmentUtil;
  final TransferProtocolTransform protocolTransform;
  final OnSendProgressUpdate? onSenderProgressUpdate;
  final OnSendStart? onSenderStart;
  final OnSendSucceed? onSenderSucceed;
  final OnSendFailed? onSenderFailed;
  final OnSendStart? onSenderServerCreated;
  final String deviceId;

  ServerSocket? _socket;

  Socket? _clientSocket;

  final _pendingVerificationSockets = <Socket>[];

  var _debugStarting = false;

  var _finished = false;

  void resetTransferStates() {
    _finished = false;
  }

  @visibleForTesting
  @mustCallSuper
  FutureOr<void> onPacketSend() {}

  void _notifyProgressUpdate(double progress) {
    onSenderProgressUpdate?.call(progress);
  }

  Future<int> startServerSocket(int verificationCode) async {
    assert(!_debugStarting, 'server socket starting');
    if (_socket != null) {
      w('startServerSocket: already started');
      return _socket!.port;
    }
    resetTransferStates();
    _debugStarting = true;
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _socket = serverSocket;
    _debugStarting = false;

    serverSocket.listen((socket) async {
      if (_clientSocket != null) {
        e('client already connected, close this connection');
        socket.destroy();
        return;
      }
      _pendingVerificationSockets.add(socket);
      i('client connected: ${socket.remoteAddress.address}:${socket.remotePort}');

      socket.transform(protocolTransform).asyncListen((event) {
        d('receive data: $event');

        if (event is TransferCommandPacket) {
          final command = event.command;
          switch (command.action) {
            case kTransferCommandActionConnect:
              if (command.code == verificationCode) {
                _clientSocket = socket;
                _pendingVerificationSockets.remove(socket);
                for (final s in _pendingVerificationSockets) {
                  s.destroy();
                }
                onSenderStart?.call();
                _processTransfer(socket);
              } else {
                e('sender verify code failed. except $verificationCode, '
                    'but got ${command.code}');
                socket.close();
                close();
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
              d('${command.action} command: progress $progress');
              _notifyProgressUpdate(progress);
              break;
          }
        }
      }, onDone: () {
        i('sender transfer done. finished: $_finished');
        if (_finished) {
          onSenderSucceed?.call();
        } else {
          onSenderFailed?.call();
        }
      }, onError: (error, stacktrace) {
        e('error: $error, stacktrace: $stacktrace');
        onSenderFailed?.call();
        close();
      });
    });
    onSenderServerCreated?.call();
    return serverSocket.port;
  }

  /// transfer data to client.
  Future<void> _processTransfer(Socket socket) async {
    Future<void> runWithLog(
        Future<int> Function(Socket) process, String name) async {
      final stopwatch = Stopwatch()..start();
      i('_processTransfer start $name');
      final count = await process(socket);
      i('_processTransfer end $name, count: $count cost: ${stopwatch.elapsed}');
    }

    // send total count
    await runWithLog((socket) async {
      final db = database.mixinDatabase;
      final count = await db.countMediaMessages().getSingle() +
          await db.countMessages().getSingle() +
          await db.countStickers().getSingle() +
          await db.assetDao.countAssets().getSingle() +
          await db.snapshotDao.countSnapshots().getSingle() +
          await db.countUsers().getSingle() +
          await db.countConversations().getSingle() +
          await db.countParticipants().getSingle() +
          await db.countPinMessages().getSingle() +
          await database.transcriptMessageDao
              .countTranscriptMessages()
              .getSingle() +
          await database.expiredMessageDao.countExpiredMessages().getSingle() +
          await database.messageMentionDao.getMessageMentionsCount() +
          await database.appDao.getAppsCount();
      await socket.addCommand(TransferDataCommand.start(
        deviceId: await getDeviceId(),
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
    await runWithLog(_processTransferAttachment, 'attachment');

    await socket.addCommand(TransferDataCommand.simple(
      deviceId: deviceId,
      action: kTransferCommandActionFinish,
    ));
  }

  Future<int> _processTransferConversation(Socket socket) async {
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

  Future<int> _processTransferUser(Socket socket) async {
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

  Future<int> _processTransferApp(Socket socket) async {
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

  Future<int> _processTransferParticipant(Socket socket) async {
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

  Future<int> _processTransferSticker(Socket socket) async {
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

  Future<int> _processTransferAsset(Socket socket) async {
    final assets = await database.assetDao.getAssets();
    for (final asset in assets) {
      await socket.addAsset(
        TransferDataAsset.fromDbAsset(asset),
      );
      await onPacketSend();
    }
    return assets.length;
  }

  Future<int> _processTransferSnapshot(Socket socket) async {
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

  Future<int> _processTransferMessage(Socket socket) async {
    var lastMessageRowId = -1;
    var count = 0;
    while (true) {
      final messages = await database.messageDao
          .getDeviceTransferMessages(lastMessageRowId, _kQueryLimit);
      if (messages.isEmpty) {
        break;
      }
      count = messages.length;
      lastMessageRowId = messages.last.item1;
      for (final message in messages) {
        await socket.addMessage(
          TransferDataMessage.fromDbMessage(message.item2),
        );
        await onPacketSend();
      }
    }
    return count;
  }

  Future<int> _processTransferMessageMention(Socket socket) async {
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

  Future<int> _processTransferTranscriptMessage(Socket socket) async {
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
      }
      if (messages.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferExpiredMessage(Socket socket) async {
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

  Future<int> _processTransferPinMessage(Socket socket) async {
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

  Future<int> _processTransferAttachment(Socket socket) async {
    final folder = attachmentUtil.mediaPath;
    // send all files in media folder
    final files = Directory(folder).list(recursive: true);
    var count = 0;
    await for (final file in files) {
      if (file is File) {
        final messageId = p.basenameWithoutExtension(file.path);
        final message =
            await database.messageDao.findMessageByMessageId(messageId);
        if (message == null) {
          d('attachment message not found ${file.path}');
          continue;
        }
        await socket.addAttachment(message.messageId, file.path);
        count++;
        await onPacketSend();
      }
    }
    return count;
  }

  void close() {
    i('sender: close transfer server');
    _clientSocket?.destroy();
    _clientSocket = null;
    _socket?.close();
    _socket = null;
  }
}
