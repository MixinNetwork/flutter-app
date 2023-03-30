import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:network_info_plus/network_info_plus.dart';

import '../blaze/blaze_message.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../db/database.dart';
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/device_transfer/device_transfer_widget.dart';
import '../utils/device_transfer/transfer_data_asset.dart';
import '../utils/device_transfer/transfer_data_command.dart';
import '../utils/device_transfer/transfer_data_conversation.dart';
import '../utils/device_transfer/transfer_data_json_wrapper.dart';
import '../utils/device_transfer/transfer_data_message.dart';
import '../utils/device_transfer/transfer_data_snapshot.dart';
import '../utils/device_transfer/transfer_data_sticker.dart';
import '../utils/device_transfer/transfer_data_user.dart';
import '../utils/device_transfer/transfer_protocol.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/platform.dart';
import 'sender.dart';

// TODO(BIN): check has primary session
class DeviceTransfer {
  DeviceTransfer({
    required this.database,
    required this.userId,
    required this.sender,
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
  final Sender sender;
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
    final result = await sender.deliver(bm);
    if (!result.success) {
      e('_sendDeviceTransferToOtherSession: ${result.errorCode}');
    }
  }

  Future<void> _sendPullToOtherSession() async {
    final command = TransferDataCommand.pull(deviceId: await getDeviceId());
    await _sendCommandAsPlainJson(command);
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

    serverSocket.listen((socket) async {
      i('client connected: ${socket.remoteAddress.address}:${socket.remotePort}');
      // listen for data
      socket.transform(const TransferProtocolTransform()).listen((event) {
        d('receive data: $event');
        if (event is TransferJsonPacket) {
          final data = event.json;
          switch (data.type) {
            case kTypeCommand:
              final command = TransferDataCommand.fromJson(data.data);
              switch (command.action) {
                case kTransferCommandActionConnect:
                  if (command.code == code) {
                    _processTransfer(socket);
                  } else {
                    e('code not match');
                    socket.close();
                  }
                  break;
              }
              break;
            default:
              e('server mode can not handle other event : $event');
              break;
          }
        }
      });
    });
    await _sendCommandAsPlainJson(command);
  }

  Future<void> _processTransfer(Socket socket) async {
    // send conversation list
    final conversations = await database.conversationDao.getConversations();
    for (final conversation in conversations) {
      await socket.addConversation(
        TransferDataConversation.fromDbConversation(conversation),
      );
    }

    final attachmentMessage = <Message>[];
    // send messages
    for (final conversation in conversations) {
      final messages = await database.messageDao
          .getMessagesByConversationId(conversation.conversationId);
      for (final message in messages) {
        await socket.addMessage(TransferDataMessage.fromDbMessage(message));
        if (message.category.isAttachment) {
          attachmentMessage.add(message);
        }
      }
    }

    d('send attachment count ${attachmentMessage.length}');

    // send sticker
    final stickers = await database.stickerDao.getStickers();
    for (final sticker in stickers) {
      await socket.addSticker(
        TransferDataSticker.fromDbSticker(sticker),
      );
    }

    // send user
    final users = await database.userDao.getUsers();
    for (final user in users) {
      await socket.addUser(
        TransferDataUser.fromDbUser(user),
      );
    }

    // send asset
    final assets = await database.assetDao.getAssets();
    for (final asset in assets) {
      await socket.addAsset(
        TransferDataAsset.fromDbAsset(asset),
      );
    }

    // send snapshot
    final snapshots = await database.snapshotDao.getSnapshots();
    for (final snapshot in snapshots) {
      await socket.addSnapshot(
        TransferDataSnapshot.fromDbSnapshot(snapshot),
      );
    }

    // send attachment
    for (final message in attachmentMessage.take(10)) {
      final path = attachmentUtil.convertAbsolutePath(
        fileName: message.mediaUrl,
        conversationId: message.conversationId,
        category: message.category,
      );
      if (!File(path).existsSync()) {
        w('attachment not exist $path');
        continue;
      }
      d('send attachment ${message.messageId} $path ${File(path).lengthSync()}');
      await socket.addAttachment(message.messageId, path);
    }
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
      final socket = await Socket.connect(ip, port);
      socket.transform(const TransferProtocolTransform()).listen((packet) {
        d('receive data: $packet');
        if (packet is TransferJsonPacket) {
          _processReceivedJsonPacket(packet.json);
        } else if (packet is TransferAttachmentPacket) {
          _processReceivedAttachmentPacket(packet);
        } else {
          e('unknown packet: $packet');
        }
      });
      await socket.addCommand(
        TransferDataCommand.connect(code: code, deviceId: await getDeviceId()),
      );
    } catch (error, stacktrace) {
      e('_handleRemotePushCommand: $error $stacktrace');
    }
  }

  Future<void> _processReceivedJsonPacket(TransferDataJsonWrapper data) async {
    switch (data.type) {
      case kTypeConversation:
        final conversation = TransferDataConversation.fromJson(data.data);
        d('client: conversation: $conversation');
        await database.conversationDao.insert(conversation.toDbConversation());
        break;
      case kTypeMessage:
        final message = TransferDataMessage.fromJson(data.data);
        d('client: message: ${message.messageId}');
        await database.messageDao.insert(message.toDbMessage(), userId);
        break;
      case kTypeAsset:
        final asset = TransferDataAsset.fromJson(data.data);
        d('client: asset: $asset');
        await database.assetDao.insertAsset(asset.toDbAsset());
        break;
      case kTypeUser:
        final user = TransferDataUser.fromJson(data.data);
        d('client: user: $user');
        await database.userDao.insert(user.toDbUser());
        break;
      case kTypeSticker:
        final sticker = TransferDataSticker.fromJson(data.data);
        d('client: sticker: $sticker');
        await database.stickerDao.insertSticker(sticker.toDbSticker());
        break;
      case kTypeSnapshot:
        final snapshot = TransferDataSnapshot.fromJson(data.data);
        d('client: snapshot: $snapshot');
        await database.snapshotDao.insert(snapshot.toDbSnapshot());
        break;
      default:
        i('unknown type: ${data.type}');
    }
  }

  Future<void> _processReceivedAttachmentPacket(
      TransferAttachmentPacket packet) async {
    d('_processReceivedAttachmentPacket: ${packet.messageId} ${packet.path}');
    final message =
        await database.messageDao.findMessageByMessageId(packet.messageId);
    if (message == null) {
      e('_processReceivedAttachmentPacket: message not found');
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
      return;
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
    final wrapper = TransferDataJsonWrapper(
      data: conversation.toJson(),
      type: kTypeConversation,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addMessage(TransferDataMessage message) {
    final wrapper = TransferDataJsonWrapper(
      data: message.toJson(),
      type: kTypeMessage,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addAttachment(String messageId, String path) {
    final packet = TransferAttachmentPacket(messageId: messageId, path: path);
    return writePacketToSink(this, packet);
  }

  Future<void> addSticker(TransferDataSticker sticker) {
    final wrapper = TransferDataJsonWrapper(
      data: sticker.toJson(),
      type: kTypeSticker,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addUser(TransferDataUser user) {
    final wrapper = TransferDataJsonWrapper(
      data: user.toJson(),
      type: kTypeUser,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addAsset(TransferDataAsset asset) {
    final wrapper = TransferDataJsonWrapper(
      data: asset.toJson(),
      type: kTypeAsset,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addSnapshot(TransferDataSnapshot snapshot) {
    final wrapper = TransferDataJsonWrapper(
      data: snapshot.toJson(),
      type: kTypeSnapshot,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addCommand(TransferDataCommand command) {
    final wrapper = TransferDataJsonWrapper(
      data: command.toJson(),
      type: kTypeCommand,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> _addTransferJson(TransferDataJsonWrapper data) =>
      writePacketToSink(this, TransferJsonPacket(data));
}
