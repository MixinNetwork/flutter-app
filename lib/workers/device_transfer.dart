import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../blaze/blaze_message.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../db/database.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/device_transfer/device_transfer_widget.dart';
import '../utils/device_transfer/json_transfer_data.dart';
import '../utils/device_transfer/transfer_data_asset.dart';
import '../utils/device_transfer/transfer_data_command.dart';
import '../utils/device_transfer/transfer_data_conversation.dart';
import '../utils/device_transfer/transfer_data_expired_message.dart';
import '../utils/device_transfer/transfer_data_message.dart';
import '../utils/device_transfer/transfer_data_participant.dart';
import '../utils/device_transfer/transfer_data_pin_message.dart';
import '../utils/device_transfer/transfer_data_snapshot.dart';
import '../utils/device_transfer/transfer_data_sticker.dart';
import '../utils/device_transfer/transfer_data_transcript_message.dart';
import '../utils/device_transfer/transfer_data_user.dart';
import '../utils/device_transfer/transfer_protocol.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/platform.dart';

typedef MessageDeliver = Future<MessageResult> Function(
    BlazeMessage blazeMessage);

const _kQueryLimit = 100;

// TODO(BIN): check has primary session
class DeviceTransfer {
  DeviceTransfer({
    required this.database,
    required this.userId,
    required this.messageDeliver,
    required this.primarySessionId,
    required this.identityNumber,
  }) : attachmentUtil = AttachmentUtilBase.of(identityNumber) {
    _subscriptions
      ..add(DeviceTransferEventBus.instance
          .on(DeviceTransferEventAction.pushToRemote)
          .listen(
            (event) => _sendPushToOtherSession(),
          ))
      ..add(DeviceTransferEventBus.instance
          .on(DeviceTransferEventAction.pullToRemote)
          .listen(
            (event) => _sendPullToOtherSession(),
          ));
  }

  final Database database;
  final String userId;
  final String identityNumber;
  final MessageDeliver messageDeliver;
  final String? primarySessionId;

  final AttachmentUtilBase attachmentUtil;

  ServerSocket? _socket;

  final List<StreamSubscription> _subscriptions = [];

  Future<void> _sendCommandAsPlainJson(TransferDataCommand command) async {
    final conversationId =
        await database.participantDao.findJoinedConversationId(userId);
    if (conversationId == null) {
      e('_sendDeviceTransferToOtherSession: conversationId is null');
      return;
    }

    final content = await jsonEncodeWithIsolate(command.toJson());
    final plainText = PlainJsonMessage.create(
      action: kDeviceTransfer,
      content: content,
    );
    final encoded = await base64EncodeWithIsolate(
        await utf8EncodeWithIsolate(await jsonEncodeWithIsolate(plainText)));
    final param = createPlainJsonParam(
      conversationId,
      userId,
      encoded,
      sessionId: primarySessionId,
    );
    final bm = createParamBlazeMessage(param);
    final result = await messageDeliver(bm);
    if (!result.success) {
      e('_sendDeviceTransferToOtherSession: ${result.errorCode}');
    }
  }

  Future<void> _sendPullToOtherSession() async {
    final command = TransferDataCommand.pull(deviceId: await getDeviceId());
    await _sendCommandAsPlainJson(command);
  }

  Future<TransferProtocolTransform> _getProtocolTransform() async {
    final fileFolder = await getTemporaryDirectory();
    final folder = p.join(fileFolder.path, 'mixin_transfer');
    try {
      await Directory(folder).create(recursive: true);
    } catch (error, stacktrace) {
      e('create folder error: $error $stacktrace');
    }
    return TransferProtocolTransform(fileFolder: folder);
  }

  Future<void> _sendPushToOtherSession() async {
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    final ipAddress = await NetworkInfo().getWifiIP();
    if (ipAddress == null) {
      e('_sendPushToOtherSession: ipAddress is null');
      return;
    }

    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 8888);
    _socket = serverSocket;

    final code = Random().nextInt(10000);

    final command = TransferDataCommand.push(
      ip: ipAddress,
      port: serverSocket.port,
      deviceId: await getDeviceId(),
      code: code,
    );

    i('_sendPushToOtherSession: server $ipAddress:${serverSocket.port}');

    final transform = await _getProtocolTransform();
    serverSocket.listen((socket) async {
      i('client connected: ${socket.remoteAddress.address}:${socket.remotePort}');

      final subscription = DeviceTransferEventBus.instance
          .on(DeviceTransferEventAction.cancelBackup)
          .listen((event) {
        serverSocket.close();
      });

      // listen for data
      var isClientVerified = false;
      socket.transform(transform).listen((event) {
        d('receive data: $event');

        if (event is TransferJsonPacket) {
          final data = event.json;
          switch (data.type) {
            case JsonTransferDataType.command:
              final command = TransferDataCommand.fromJson(data.data);
              switch (command.action) {
                case kTransferCommandActionConnect:
                  if (command.code == code) {
                    isClientVerified = true;
                    DeviceTransferEventBus.instance
                        .fire(DeviceTransferEventAction.onBackupStart);
                    _processTransfer(socket);
                  } else {
                    e('code not match');
                    socket.close();
                  }
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
        i('client(${socket.remoteAddress.address}:${socket.remotePort}) disconnected');
        if (isClientVerified) {
          i('verified client exit, close server socket($ipAddress:${serverSocket.port})');
          serverSocket.close();
          _socket = null;
        }
        DeviceTransferEventBus.instance
            .fire(DeviceTransferEventAction.onBackupSucceed);
        subscription.cancel();
      }, onError: (error, stacktrace) {
        e('client(${socket.remoteAddress.address}:${socket.remotePort}) error: $error $stacktrace');
        DeviceTransferEventBus.instance
            .fire(DeviceTransferEventAction.onBackupFailed);
        subscription.cancel();
      });
    });
    await _sendCommandAsPlainJson(command);
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
        await socket.addUser(
          TransferDataUser.fromDbUser(user),
        );
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
    final files = Directory(folder).listSync(recursive: true);
    for (final file in files) {
      if (file is File) {
        final messageId = p.basenameWithoutExtension(file.path);
        final message =
            await database.messageDao.findMessageByMessageId(messageId);
        if (message == null) {
          d('attachment message not found ${file.path}');
          continue;
        }
        await socket.addAttachment(message.messageId, file.path);
      }
    }
    return files.length;
  }

  void handleRemoteCommand(TransferDataCommand command) {
    d('handleRemoteCommand: $command');
    switch (command.action) {
      case kTransferCommandActionPush:
        _handleRemotePushCommand(command.ip!, command.port!, command.code!);
        break;
      case kTransferCommandActionPull:
        _sendPushToOtherSession();
        break;
      default:
        e('handleRemoteCommand: unknown action ${command.action}');
        return;
    }
  }

  Future<void> _handleRemotePushCommand(String ip, int port, int code) async {
    d('_handleRemotePushCommand: $ip:$port ($code)');
    try {
      final transform = await _getProtocolTransform();
      d('connect to $ip:$port');
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 10),
      );
      final subscription = DeviceTransferEventBus.instance
          .on(DeviceTransferEventAction.cancelRestore)
          .listen((event) {
        socket.close();
      });
      socket.transform(transform).listen(
        (packet) {
          if (packet is TransferJsonPacket) {
            _processReceivedJsonPacket(packet.json);
          } else if (packet is TransferAttachmentPacket) {
            _processReceivedAttachmentPacket(packet);
          } else {
            e('unknown packet: $packet');
          }
        },
        onDone: () {
          DeviceTransferEventBus.instance
              .fire(DeviceTransferEventAction.onRestoreSucceed);
          subscription.cancel();
        },
        onError: (error, stacktrace) {
          e('_handleRemotePushCommand: $error $stacktrace');
          DeviceTransferEventBus.instance
              .fire(DeviceTransferEventAction.onRestoreFailed);
          subscription.cancel();
        },
      );
      await socket.addCommand(
        TransferDataCommand.connect(code: code, deviceId: await getDeviceId()),
      );
      DeviceTransferEventBus.instance
          .fire(DeviceTransferEventAction.onBackupStart);
    } catch (error, stacktrace) {
      e('_handleRemotePushCommand: $error $stacktrace');
    }
  }

  Future<void> _processReceivedJsonPacket(JsonTransferData data) async {
    try {
      switch (data.type) {
        case JsonTransferDataType.conversation:
          final conversation = TransferDataConversation.fromJson(data.data);
          d('client: conversation: $conversation');
          final local = await database.conversationDao
              .conversationById(conversation.conversationId)
              .getSingleOrNull();
          if (local != null) {
            i('conversation already exist: ${conversation.conversationId}');
            return;
          }
          await database.conversationDao
              .insert(conversation.toDbConversation());
          break;
        case JsonTransferDataType.message:
          final message = TransferDataMessage.fromJson(data.data);
          d('client: message: ${data.data}');
          final local = await database.messageDao
              .findMessageByMessageId(message.messageId);
          if (local != null) {
            d('message already exist: ${message.messageId}');
            return;
          }
          final dbMessage =
              message.toDbMessage().copyWith(status: MessageStatus.read);
          await database.messageDao.insert(dbMessage, userId);
          await database.ftsDatabase.insertFts(dbMessage);
          break;
        case JsonTransferDataType.asset:
          final asset = TransferDataAsset.fromJson(data.data);
          d('client: asset: $asset');
          await database.assetDao.insertAsset(asset.toDbAsset());
          break;
        case JsonTransferDataType.user:
          final user = TransferDataUser.fromJson(data.data);
          d('client: user: $user');
          await database.userDao
              .insert(user.toDbUser(), updateIfConflict: false);
          break;
        case JsonTransferDataType.sticker:
          final sticker = TransferDataSticker.fromJson(data.data);
          d('client: sticker: $sticker');
          await database.stickerDao.insertSticker(sticker.toDbSticker());
          break;
        case JsonTransferDataType.snapshot:
          final snapshot = TransferDataSnapshot.fromJson(data.data);
          d('client: snapshot: $snapshot');
          await database.snapshotDao
              .insert(snapshot.toDbSnapshot(), updateIfConflict: false);
          break;
        case JsonTransferDataType.command:
          final command = TransferDataCommand.fromJson(data.data);
          d('client: command: $command');
          break;
        case JsonTransferDataType.expiredMessage:
          final expiredMessage = TransferDataExpiredMessage.fromJson(data.data);
          d('client: expiredMessage: $expiredMessage');
          await database.expiredMessageDao.insert(
            messageId: expiredMessage.messageId,
            expireIn: expiredMessage.expireIn,
            expireAt: expiredMessage.expireAt,
            updateIfConflict: false,
          );
          break;
        case JsonTransferDataType.transcriptMessage:
          final transcriptMessage =
              TransferDataTranscriptMessage.fromJson(data.data);
          d('client: transcriptMessage: $transcriptMessage');
          await database.transcriptMessageDao.insertAll(
            [transcriptMessage.toDbTranscriptMessage()],
            mode: InsertMode.insertOrIgnore,
          );
          break;
        case JsonTransferDataType.participant:
          final participant = TransferDataParticipant.fromJson(data.data);
          d('client: participant: $participant');
          await database.participantDao.insert(
            participant.toDbParticipant(),
            updateIfConflict: false,
          );
          break;
        case JsonTransferDataType.pinMessage:
          final pinMessage = TransferDataPinMessage.fromJson(data.data);
          d('client: pinMessage: $pinMessage');
          await database.pinMessageDao.insert(
            pinMessage.toDbPinMessage(),
            updateIfConflict: false,
          );
          break;
        case JsonTransferDataType.unknown:
          i('unknown type: ${data.type}');
          break;
      }
    } catch (error, stacktrace) {
      e('_processReceivedJsonPacket: ${data.data} \n $error $stacktrace');
    }
  }

  Future<void> _processReceivedAttachmentPacket(
      TransferAttachmentPacket packet) async {
    d('_processReceivedAttachmentPacket: ${packet.messageId} ${packet.path}');
    final message =
        await database.messageDao.findMessageByMessageId(packet.messageId);

    Future<void> deletePacketFile() async {
      try {
        await File(packet.path).delete();
      } catch (error, stacktrace) {
        e('_processReceivedAttachmentPacket: $error $stacktrace');
      }
    }

    if (message == null) {
      e('_processReceivedAttachmentPacket: message not found ${packet.messageId}');
      await deletePacketFile();
      return;
    }
    final path = attachmentUtil.convertAbsolutePath(
      category: message.category,
      conversationId: message.conversationId,
      fileName: message.mediaUrl,
    );
    final file = File(path);
    if (file.existsSync()) {
      // already exist
      i('_processReceivedAttachmentPacket: already exist');
      await deletePacketFile();
      return;
    }
    // check file parent folder
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    try {
      File(packet.path).renameSync(file.path);
    } catch (error, stacktrace) {
      e('_processReceivedAttachmentPacket: $error $stacktrace');
    }
  }

  void dispose() {
    d('dispose: device transfer');
    _socket?.close();
  }
}

extension SocketExtension on Socket {
  Future<void> addConversation(TransferDataConversation conversation) {
    final wrapper = JsonTransferData(
      data: conversation.toJson(),
      type: JsonTransferDataType.conversation,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addMessage(TransferDataMessage message) {
    final wrapper = JsonTransferData(
      data: message.toJson(),
      type: JsonTransferDataType.message,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addAttachment(String messageId, String path) {
    final packet = TransferAttachmentPacket(messageId: messageId, path: path);
    return writePacketToSink(this, packet);
  }

  Future<void> addSticker(TransferDataSticker sticker) {
    final wrapper = JsonTransferData(
      data: sticker.toJson(),
      type: JsonTransferDataType.sticker,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addUser(TransferDataUser user) {
    final wrapper = JsonTransferData(
      data: user.toJson(),
      type: JsonTransferDataType.user,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addAsset(TransferDataAsset asset) {
    final wrapper = JsonTransferData(
      data: asset.toJson(),
      type: JsonTransferDataType.asset,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addSnapshot(TransferDataSnapshot snapshot) {
    final wrapper = JsonTransferData(
      data: snapshot.toJson(),
      type: JsonTransferDataType.snapshot,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addCommand(TransferDataCommand command) {
    final wrapper = JsonTransferData(
      data: command.toJson(),
      type: JsonTransferDataType.command,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addTranscriptMessage(
      TransferDataTranscriptMessage transcriptMessage) {
    final wrapper = JsonTransferData(
      data: transcriptMessage.toJson(),
      type: JsonTransferDataType.transcriptMessage,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addParticipant(TransferDataParticipant participant) {
    final wrapper = JsonTransferData(
      data: participant.toJson(),
      type: JsonTransferDataType.participant,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addPinMessage(TransferDataPinMessage pinMessage) {
    final wrapper = JsonTransferData(
      data: pinMessage.toJson(),
      type: JsonTransferDataType.pinMessage,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addExpiredMessage(TransferDataExpiredMessage expiredMessage) {
    final wrapper = JsonTransferData(
      data: expiredMessage.toJson(),
      type: JsonTransferDataType.expiredMessage,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> _addTransferJson(JsonTransferData data) =>
      writePacketToSink(this, TransferJsonPacket(data));
}
