import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';

import '../../db/database.dart';
import '../../db/mixin_database.dart' as db;
import '../attachment/attachment_util.dart';
import '../extension/extension.dart';
import '../logger.dart';
import 'cipher.dart';
import 'json_transfer_data.dart';
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
import 'transfer_data_safe_snapshot.dart';
import 'transfer_data_snapshot.dart';
import 'transfer_data_sticker.dart';
import 'transfer_data_token.dart';
import 'transfer_data_transcript_message.dart';
import 'transfer_data_user.dart';
import 'transfer_protocol.dart';

typedef OnReceiverStart = void Function();
typedef OnReceiverSucceed = void Function();
typedef OnReceiverFailed = void Function();

/// [progress] is between 0.0 and 100.0
typedef OnReceiverProgressUpdate = void Function(double progress);

typedef OnReceiverNetworkSpeedUpdate = void Function(double speed);

class DeviceTransferReceiver {
  DeviceTransferReceiver({
    required this.database,
    required this.attachmentUtil,
    required this.userId,
    required this.protocolTempFileDir,
    required this.deviceId,
    this.onReceiverStart,
    this.onReceiverSucceed,
    this.onReceiverFailed,
    this.onReceiverProgressUpdate,
    this.onConnectedToServer,
    this.onNetworkSpeedUpdate,
  });

  final Database database;
  final AttachmentUtilBase attachmentUtil;
  final String userId;
  final String protocolTempFileDir;
  final String deviceId;
  final _speedCalculator = SpeedCalculator();

  final OnReceiverStart? onReceiverStart;
  final OnReceiverSucceed? onReceiverSucceed;
  final OnReceiverFailed? onReceiverFailed;
  final OnReceiverProgressUpdate? onReceiverProgressUpdate;
  final OnReceiverStart? onConnectedToServer;
  final OnReceiverNetworkSpeedUpdate? onNetworkSpeedUpdate;

  TransferSocket? _socket;
  int _total = 0;
  int _progress = 0;
  var _lastProgressNotifyTime = DateTime(0);

  var _finished = false;

  void _resetTransferStates() {
    _total = 0;
    _progress = 0;
    _finished = false;
    _lastProgressNotifyTime = DateTime(0);
    _speedCalculator.reset();
  }

  Future<void> _notifyProgressUpdate() async {
    _progress++;
    final progress =
        _total == 0 ? 0.0 : (_progress / _total * 100.0).clamp(0.0, 100.0);
    onReceiverProgressUpdate?.call(progress);
    if (DateTime.now().difference(_lastProgressNotifyTime) >
        const Duration(milliseconds: 200)) {
      _lastProgressNotifyTime = DateTime.now();
      await _socket?.addCommand(
        TransferDataCommand.progress(deviceId: deviceId, progress: progress),
      );
      i('device transfer receiver: progress: $progress $_progress/$_total');
    }
  }

  Future<void> _notifyProgressComplete() async {
    onReceiverProgressUpdate?.call(100);
    await _socket?.addCommand(
      TransferDataCommand.progress(deviceId: deviceId, progress: 100),
    );
  }

  Future<void> connectToServer(
    String ip,
    int port,
    int code,
    TransferSecretKey secretKey,
  ) async {
    i('receiver connect to $ip:$port');
    if (_socket != null) {
      w('socket is not null, close it first');
      close();
    }
    _finished = false;
    final socket = await Socket.connect(
      ip,
      port,
      timeout: const Duration(minutes: 1),
    );
    _resetTransferStates();
    _socket = TransferSocket(socket, secretKey);
    d('connected to $ip:$port. my port: ${socket.port}');
    Stream<TransferPacket>.eventTransformed(
      socket,
      (sink) => TransferProtocolSink(
        sink,
        protocolTempFileDir,
        secretKey,
        onHandleBytes: (size) {
          _speedCalculator.add(size);
          onNetworkSpeedUpdate?.call(_speedCalculator.speed);
        },
      ),
    ).asyncListen(
      (packet) async {
        try {
          if (packet is TransferDataPacket) {
            await _notifyProgressUpdate();
            await _processReceivedJsonPacket(packet.data);
          } else if (packet is TransferCommandPacket) {
            await _processReceivedCommand(packet.command);
          } else if (packet is TransferAttachmentPacket) {
            await _processReceivedAttachmentPacket(packet);
          } else {
            e('unknown packet: $packet');
          }
        } catch (error, stacktrace) {
          if (_socket == null) {
            e('socket is null, ignore error $error');
            return;
          }
          e('process packet error: $error $stacktrace');
          close();
        }
      },
      onDone: () {
        d('receiver: socket done. finished: $_finished');
        if (_finished) {
          onReceiverSucceed?.call();
        } else {
          onReceiverFailed?.call();
        }
        close();
      },
      onError: (error, stacktrace) {
        e('receiver: socket process error, $error $stacktrace');
        onReceiverFailed?.call();
        close();
      },
      cancelOnError: true,
    );
    await _socket?.addCommand(
      TransferDataCommand.connect(
        code: code,
        deviceId: deviceId,
        userId: userId,
      ),
    );
    onConnectedToServer?.call();
  }

  Future<void> _processReceivedCommand(TransferDataCommand command) async {
    d('client: command: $command');
    switch (command.action) {
      case kTransferCommandActionFinish:
        i('${command.action} command: finish receiver socket');
        _finished = true;
        await _notifyProgressComplete();
        assert(_socket != null, 'socket is null');
        await _socket?.addCommand(
          TransferDataCommand.simple(
            deviceId: deviceId,
            action: kTransferCommandActionFinish,
          ),
        );
      case kTransferCommandActionClose:
        i('${command.action} command: close receiver socket');
        close();
      case kTransferCommandActionStart:
        i('${command.action} command: start receiver');
        _total = command.total!;
        onReceiverStart?.call();
        onReceiverProgressUpdate?.call(0);
    }
  }

  Future<void> _processReceivedJsonPacket(JsonTransferData data) async {
    try {
      switch (data.type) {
        case JsonTransferDataType.conversation:
          final conversation = TransferDataConversation.fromJson(data.data);
          d('client: conversation: $conversation');
          final local =
              await database.conversationDao
                  .conversationById(conversation.conversationId)
                  .getSingleOrNull();
          if (local != null) {
            i('conversation already exist: ${conversation.conversationId}');
            return;
          }
          await database.conversationDao.insert(
            conversation.toDbConversation(),
          );
        case JsonTransferDataType.message:
          final message = TransferDataMessage.fromJson(data.data);

          if (message.category.isCall) {
            i('ignore kraken message: ${message.messageId}');
            return;
          }

          d('client: message: $message');
          final local = await database.messageDao.findMessageByMessageId(
            message.messageId,
          );
          if (local != null) {
            d('message already exist: ${message.messageId}');
            return;
          }
          final dbMessage = message.toDbMessage().copyWith(
            status: MessageStatus.read,
          );
          await database.messageDao.insert(dbMessage, userId);
          await database.ftsDatabase.insertFts(dbMessage);
        case JsonTransferDataType.asset:
          final asset = TransferDataAsset.fromJson(data.data);
          d('client: asset: $asset');
          await database.assetDao.insertAsset(asset.toDbAsset());
        case JsonTransferDataType.token:
          final token = TransferDataToken.fromJson(data.data);
          d('client: token: $token');
          await database.tokenDao.insertToken(token.toDbToken());
        case JsonTransferDataType.user:
          final user = TransferDataUser.fromJson(data.data);
          d('client: user: $user');
          await database.userDao.insert(
            user.toDbUser(),
            updateIfConflict: false,
          );
        case JsonTransferDataType.sticker:
          final sticker = TransferDataSticker.fromJson(data.data);
          d('client: sticker: $sticker');
          await database.stickerDao.insertSticker(sticker.toDbSticker());
        case JsonTransferDataType.snapshot:
          final snapshot = TransferDataSnapshot.fromJson(data.data);
          d('client: snapshot: $snapshot');
          await database.snapshotDao.insert(
            snapshot.toDbSnapshot(),
            updateIfConflict: false,
          );
        case JsonTransferDataType.safeSnapshot:
          final safeSnapshot = TransferDataSafeSnapshot.fromJson(data.data);
          d('client: safeSnapshot: $safeSnapshot');
          await database.safeSnapshotDao.insert(
            safeSnapshot.toDbSafeSnapshot(),
            updateIfConflict: false,
          );
        case JsonTransferDataType.expiredMessage:
          final expiredMessage = TransferDataExpiredMessage.fromJson(data.data);
          d('client: expiredMessage: $expiredMessage');
          await database.expiredMessageDao.insert(
            messageId: expiredMessage.messageId,
            expireIn: expiredMessage.expireIn,
            expireAt: expiredMessage.expireAt,
            updateIfConflict: false,
          );
        case JsonTransferDataType.transcriptMessage:
          final transcriptMessage = TransferDataTranscriptMessage.fromJson(
            data.data,
          );
          d('client: transcriptMessage: $transcriptMessage');
          await database.transcriptMessageDao.insertAll([
            transcriptMessage.toDbTranscriptMessage(),
          ], mode: InsertMode.insertOrIgnore);
        case JsonTransferDataType.participant:
          final participant = TransferDataParticipant.fromJson(data.data);
          d('client: participant: $participant');
          await database.participantDao.insert(
            participant.toDbParticipant(),
            updateIfConflict: false,
          );
        case JsonTransferDataType.pinMessage:
          final pinMessage = TransferDataPinMessage.fromJson(data.data);
          d('client: pinMessage: $pinMessage');
          await database.pinMessageDao.insert(
            pinMessage.toDbPinMessage(),
            updateIfConflict: false,
          );
        case JsonTransferDataType.messageMention:
          final messageMention = db.MessageMention.fromJson(data.data);
          d('client: messageMention: $messageMention');
          await database.messageMentionDao.insert(
            messageMention,
            updateIfConflict: false,
          );
        case JsonTransferDataType.app:
          final app = TransferDataApp.fromJson(data.data);
          d('client: app: $app');
          await database.appDao.insert(app.toDbApp(), updateIfConflict: false);
        case JsonTransferDataType.inscriptionItem:
          final inscription = db.InscriptionItem.fromJson(data.data);
          d('client: inscription: $inscription');
          await database.inscriptionItemDao.insert(
            inscription,
            updateIfConflict: false,
          );
        case JsonTransferDataType.inscriptionCollection:
          final collection = db.InscriptionCollection.fromJson(data.data);
          d('client: InscriptionCollection: $collection');
          await database.inscriptionCollectionDao.insert(
            collection,
            updateIfConflict: false,
          );
        case JsonTransferDataType.unknown:
          i('unknown type: ${data.type}');
      }
    } catch (error, stacktrace) {
      e('_processReceivedJsonPacket: ${data.data}');
      e('_processReceivedJsonPacket', error, stacktrace);
    }
  }

  Future<void> _processReceivedAttachmentPacket(
    TransferAttachmentPacket packet,
  ) async {
    d('_processReceivedAttachmentPacket: ${packet.messageId} ${packet.path}');

    void deletePacketFile() {
      try {
        File(packet.path).deleteSync();
      } catch (error) {
        e('_processReceivedAttachmentPacket: deletePacketFile', error);
      }
    }

    final tm =
        await database.transcriptMessageDao
            .transcriptMessageByMessageId(packet.messageId)
            .getSingleOrNull();
    if (tm != null) {
      final path = attachmentUtil.convertAbsolutePath(
        category: tm.category,
        fileName: tm.mediaUrl,
        isTranscript: true,
      );
      if (path.isEmpty) {
        e(
          '_processReceivedAttachmentPacket: transcript attachment path is empty.'
          ' ${tm.messageId} ${tm.mediaUrl} ${tm.category}',
        );
      } else {
        try {
          final target = File(path);
          if (!target.parent.existsSync()) {
            target.parent.createSync(recursive: true);
          }
          if (!target.existsSync()) {
            File(packet.path).copySync(path);
          } else {
            e('transcript message found, but file already exits: $path');
          }
        } catch (error, stacktrace) {
          e('_processReceivedAttachmentPacket: $error $stacktrace');
        }
      }
    }

    final message = await database.messageDao.findMessageByMessageId(
      packet.messageId,
    );

    if (message == null) {
      e(
        '_processReceivedAttachmentPacket: message is null ${packet.messageId}',
      );
      deletePacketFile();
      return;
    }

    final path = attachmentUtil.convertAbsolutePath(
      category: message.category,
      conversationId: message.conversationId,
      fileName: message.mediaUrl,
    );

    if (path.isEmpty) {
      e(
        '_processReceivedAttachmentPacket: path is empty. ${message.messageId} ${message.category} ${message.mediaUrl}',
      );
      deletePacketFile();
      return;
    }

    final file = File(path);
    try {
      if (file.existsSync()) {
        // already exist
        i('_processReceivedAttachmentPacket: already exist. ${file.path}');
        deletePacketFile();
        return;
      }
      // check file parent folder
      final parent = file.parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
    } catch (error, stacktrace) {
      e(
        '_processReceivedAttachmentPacket: ${message.messageId} ${message.category} ${message.mediaUrl}',
        error,
        stacktrace,
      );
      deletePacketFile();
      return;
    }

    try {
      File(packet.path).renameSync(file.path);
    } catch (error, stacktrace) {
      e('_processReceivedAttachmentPacket: $error $stacktrace');
    }
  }

  void close() {
    i('receiver closing');
    if (_socket == null) {
      e('receiver closing, but socket is null');
    }
    _socket?.close();
    _socket?.destroy();
    _socket = null;
  }
}
