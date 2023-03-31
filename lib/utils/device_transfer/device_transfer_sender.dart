import 'dart:io';

import 'package:path/path.dart' as p;

import '../../db/database.dart';
import '../attachment/attachment_util.dart';
import '../logger.dart';
import '../platform.dart';
import 'device_transfer_widget.dart';
import 'json_transfer_data.dart';
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
    this.onProgressUpdate,
    this.onSendStart,
    this.onSendSucceed,
    this.onSendFailed,
  });

  final Database database;
  final AttachmentUtilBase attachmentUtil;
  final TransferProtocolTransform protocolTransform;
  final OnSendProgressUpdate? onProgressUpdate;
  final OnSendStart? onSendStart;
  final OnSendSucceed? onSendSucceed;
  final OnSendFailed? onSendFailed;
  final String deviceId;

  ServerSocket? _socket;

  Socket? _clientSocket;

  final _pendingVerificationSockets = <Socket>[];

  var _debugStarting = false;

  var _totalCount = 0;
  var _progress = 0;

  void _notifyProgressUpdate() {
    _progress++;
    assert(_totalCount != 0, 'total count is 0');
    final progress = _totalCount == 0
        ? 0.0
        : (_progress / _totalCount * 100).clamp(0.0, 100.0);
    onProgressUpdate?.call(progress);
  }

  Future<int> startServerSocket(int verificationCode) async {
    assert(!_debugStarting, 'server socket starting');
    _totalCount = 0;
    if (_socket != null) {
      w('startServerSocket: already started');
      return _socket!.port;
    }
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
      final subscription = DeviceTransferEventBus.instance
          .on(DeviceTransferEventAction.cancelBackup)
          .listen((event) {
        close();
      });

      socket.transform(protocolTransform).listen((event) {
        d('receive data: $event');

        if (event is TransferJsonPacket) {
          final data = event.json;
          switch (data.type) {
            case JsonTransferDataType.command:
              final command = TransferDataCommand.fromJson(data.data);
              switch (command.action) {
                case kTransferCommandActionConnect:
                  if (command.code == verificationCode) {
                    _clientSocket = socket;
                    _pendingVerificationSockets.remove(socket);
                    for (final s in _pendingVerificationSockets) {
                      s.destroy();
                    }
                    onSendStart?.call();
                    _processTransfer(socket);
                  } else {
                    e('code not match');
                    socket.close();
                  }
                  break;
                case kTransferCommandActionClose:
                case kTransferCommandActionFinish:
                  i('client(${socket.remoteAddress.address}:${socket.remotePort}) close connection');
                  close();
                  break;
              }
              break;
            case JsonTransferDataType.conversation:
            case JsonTransferDataType.message:
            case JsonTransferDataType.sticker:
            case JsonTransferDataType.asset:
            case JsonTransferDataType.snapshot:
            case JsonTransferDataType.user:
            case JsonTransferDataType.expiredMessage:
            case JsonTransferDataType.transcriptMessage:
            case JsonTransferDataType.participant:
            case JsonTransferDataType.pinMessage:
            case JsonTransferDataType.unknown:
              e('unknown type: ${data.type}');
              d('data: $data');
              break;
          }
        }
      }, onDone: () {
        onSendSucceed?.call();
        subscription.cancel();
      }, onError: (error, stacktrace) {
        onSendFailed?.call();
        subscription.cancel();
        close();
      });
    });
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
          await database.expiredMessageDao.countExpiredMessages().getSingle();
      await socket.addCommand(TransferDataCommand.start(
        deviceId: await getDeviceId(),
        total: count,
      ));
      _totalCount = count;
      return count;
    }, 'send_total_count');

    onProgressUpdate?.call(0);

    await runWithLog(_processTransferConversation, 'conversation');
    await runWithLog(_processTransferUser, 'user');
    await runWithLog(_processTransferParticipant, 'participant');
    await runWithLog(_processTransferSticker, 'sticker');
    await runWithLog(_processTransferAsset, 'asset');
    await runWithLog(_processTransferSnapshot, 'snapshot');
    await runWithLog(_processTransferTranscriptMessage, 'transcriptMessage');
    await runWithLog(_processTransferPinMessage, 'pinMessage');
    await runWithLog(_processTransferMessage, 'message');
    await runWithLog(_processTransferExpiredMessage, 'expiredMessage');
    await runWithLog(_processTransferAttachment, 'attachment');

    _progress = _totalCount;
    onProgressUpdate?.call(100);

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
        _notifyProgressUpdate();
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
        _notifyProgressUpdate();
      }
      if (users.length < _kQueryLimit) {
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
        _notifyProgressUpdate();
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
        _notifyProgressUpdate();
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
      _notifyProgressUpdate();
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
        _notifyProgressUpdate();
      }
      if (snapshots.length < _kQueryLimit) {
        break;
      }
    }
    return offset;
  }

  Future<int> _processTransferMessage(Socket socket) async {
    int? lastMessageRowId;
    var count = 0;
    while (true) {
      final messages =
          await database.messageDao.getMessages(lastMessageRowId, _kQueryLimit);
      if (messages.isEmpty) {
        break;
      }
      count = messages.length;
      lastMessageRowId = messages.last.item1;
      for (final message in messages) {
        await socket.addMessage(
          TransferDataMessage.fromDbMessage(message.item2),
        );
        _notifyProgressUpdate();
      }
    }
    return count;
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
        _notifyProgressUpdate();
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
        _notifyProgressUpdate();
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
        _notifyProgressUpdate();
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
        _notifyProgressUpdate();
      }
    }
    return count;
  }

  void close() {
    _clientSocket?.destroy();
    _clientSocket = null;
    _socket?.close();
    _socket = null;
    _totalCount = 0;
  }
}
