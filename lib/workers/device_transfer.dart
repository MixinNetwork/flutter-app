import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:mixin_bot_sdk_dart/mixin_bot_sdk_dart.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../blaze/blaze_message.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../db/database.dart';
import '../db/extension/message_category.dart';
import '../db/mixin_database.dart';
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
            case JsonTransferDataType.command:
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

    d('send attachment count ${attachmentMessage.length}');

    // send sticker
    final stickers = await database.stickerDao.getStickers();
    for (final sticker in stickers) {
      await socket.addSticker(
        TransferDataSticker.fromDbSticker(sticker),
      );
    }

    d('send sticker count ${stickers.length}');

    // send user
    final users = await database.userDao.getUsers();
    for (final user in users) {
      await socket.addUser(
        TransferDataUser.fromDbUser(user),
      );
    }

    d('send user count ${users.length}');

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
      d('send message count ${messages.length}');
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
      d('connect to $ip:$port');
      final socket = await Socket.connect(ip, port);
      socket.transform(const TransferProtocolTransform()).listen((packet) {
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
          await database.messageDao.insert(
              message.toDbMessage().copyWith(status: MessageStatus.read),
              userId);
          break;
        case JsonTransferDataType.asset:
          final asset = TransferDataAsset.fromJson(data.data);
          d('client: asset: $asset');
          await database.assetDao.insertAsset(asset.toDbAsset());
          break;
        case JsonTransferDataType.user:
          final user = TransferDataUser.fromJson(data.data);
          d('client: user: $user');
          await database.userDao.insert(user.toDbUser());
          break;
        case JsonTransferDataType.sticker:
          final sticker = TransferDataSticker.fromJson(data.data);
          d('client: sticker: $sticker');
          await database.stickerDao.insertSticker(sticker.toDbSticker());
          break;
        case JsonTransferDataType.snapshot:
          final snapshot = TransferDataSnapshot.fromJson(data.data);
          d('client: snapshot: $snapshot');
          await database.snapshotDao.insert(snapshot.toDbSnapshot());
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
          );
          break;
        case JsonTransferDataType.transcriptMessage:
          final transcriptMessage =
              TransferDataTranscriptMessage.fromJson(data.data);
          d('client: transcriptMessage: $transcriptMessage');
          await database.transcriptMessageDao
              .insertAll([transcriptMessage.toDbTranscriptMessage()]);
          break;
        case JsonTransferDataType.participant:
          final participant = TransferDataParticipant.fromJson(data.data);
          d('client: participant: $participant');
          await database.participantDao.insert(participant.toDbParticipant());
          break;
        case JsonTransferDataType.pinMessage:
          final pinMessage = TransferDataPinMessage.fromJson(data.data);
          d('client: pinMessage: $pinMessage');
          await database.pinMessageDao.insert(pinMessage.toDbPinMessage());
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
    if (message == null) {
      e('_processReceivedAttachmentPacket: message not found ${packet.messageId}');
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

  Future<void> _addTransferJson(JsonTransferData data) =>
      writePacketToSink(this, TransferJsonPacket(data));
}
