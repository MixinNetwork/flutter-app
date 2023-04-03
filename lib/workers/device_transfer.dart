import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

import '../blaze/blaze_message.dart';
import '../blaze/vo/message_result.dart';
import '../blaze/vo/plain_json_message.dart';
import '../constants/constants.dart';
import '../db/database.dart';
import '../utils/attachment/attachment_util.dart';
import '../utils/device_transfer/device_transfer_receiver.dart';
import '../utils/device_transfer/device_transfer_sender.dart';
import '../utils/device_transfer/device_transfer_widget.dart';
import '../utils/device_transfer/transfer_data_command.dart';
import '../utils/device_transfer/transfer_protocol.dart';
import '../utils/event_bus.dart';
import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';
import '../utils/platform.dart';

typedef MessageDeliver = Future<MessageResult> Function(
  BlazeMessage blazeMessage,
);

// TODO(BIN): check has primary session
class DeviceTransfer {
  DeviceTransfer({
    required this.database,
    required this.userId,
    required this.messageDeliver,
    required this.primarySessionId,
    required this.sender,
    required this.receiver,
  }) {
    _subscriptions.add(EventBus.instance.on
        .whereType<DeviceTransferCommand>()
        .listen((event) async {
      switch (event) {
        case DeviceTransferCommand.pullToRemote:
          await _sendPullToOtherSession();
          break;
        case DeviceTransferCommand.pushToRemote:
          await _sendPushToOtherSession();
          break;
        case DeviceTransferCommand.cancelRestore:
          receiver.close();
          break;
        case DeviceTransferCommand.cancelBackup:
          sender.close();
          break;
      }
    }));
  }

  static Future<DeviceTransfer> create({
    required Database database,
    required String userId,
    required MessageDeliver messageDeliver,
    required String? primarySessionId,
    required String identityNumber,
  }) async {
    final attachmentUtil = AttachmentUtilBase.of(identityNumber);
    final transform = await _getProtocolTransform();
    final deviceId = await getDeviceId();
    final sender = DeviceTransferSender(
      database: database,
      attachmentUtil: attachmentUtil,
      protocolTransform: transform,
      deviceId: deviceId,
      onSenderStart: () {
        DeviceTransferEventBus.instance
            .fire(DeviceTransferCallbackType.onBackupStart);
      },
      onSenderSucceed: () {
        DeviceTransferEventBus.instance
            .fire(DeviceTransferCallbackType.onBackupSucceed);
      },
      onSenderFailed: () {
        DeviceTransferEventBus.instance
            .fire(DeviceTransferCallbackType.onBackupFailed);
      },
      onSenderProgressUpdate: (progress) {
        DeviceTransferEventBus.instance.fire(
          DeviceTransferCallbackType.onBackupProgress,
          progress,
        );
      },
    );
    final receiver = DeviceTransferReceiver(
      database: database,
      userId: userId,
      attachmentUtil: attachmentUtil,
      protocolTransform: transform,
      deviceId: deviceId,
      onReceiverStart: () {
        DeviceTransferEventBus.instance
            .fire(DeviceTransferCallbackType.onRestoreStart);
      },
      onReceiverSucceed: () {
        DeviceTransferEventBus.instance
            .fire(DeviceTransferCallbackType.onRestoreSucceed);
      },
      onReceiverFailed: () {
        DeviceTransferEventBus.instance
            .fire(DeviceTransferCallbackType.onRestoreFailed);
      },
      onReceiverProgressUpdate: (progress) {
        DeviceTransferEventBus.instance.fire(
          DeviceTransferCallbackType.onRestoreProgress,
          progress,
        );
      },
    );

    return DeviceTransfer(
      database: database,
      userId: userId,
      messageDeliver: messageDeliver,
      primarySessionId: primarySessionId,
      sender: sender,
      receiver: receiver,
    );
  }

  final Database database;
  final String userId;
  final MessageDeliver messageDeliver;
  final String? primarySessionId;

  final DeviceTransferSender sender;
  final DeviceTransferReceiver receiver;

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

  static Future<TransferProtocolTransform> _getProtocolTransform() async {
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
    String? ipAddress;
    try {
      ipAddress = await NetworkInfo().getWifiIP();
    } catch (error) {
      assert(() {
        // for test
        ipAddress = '0.0.0.0';
        return true;
      }());
    }
    if (ipAddress == null) {
      e('_sendPushToOtherSession: ipAddress is null');
      return;
    }

    final code = Random().nextInt(10000);

    final port = await sender.startServerSocket(code);
    i('_sendPushToOtherSession: server addr $ipAddress:$port');

    final command = TransferDataCommand.push(
      ip: ipAddress!,
      port: port,
      deviceId: await getDeviceId(),
      code: code,
    );

    await _sendCommandAsPlainJson(command);
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
    await receiver.connectToServer(ip, port, code);
  }

  void dispose() {
    d('dispose: device transfer');
    _subscriptions
      ..forEach((s) => s.cancel())
      ..clear();
    sender.close();
    receiver.close();
  }
}
