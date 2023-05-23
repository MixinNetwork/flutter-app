import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:synchronized/synchronized.dart';

import '../../db/mixin_database.dart';
import '../logger.dart';
import 'cipher.dart';
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

abstract class TransferSocket {
  factory TransferSocket(Socket socket, TransferSecretKey secretKey) =>
      _TransferSocket(socket, secretKey);

  TransferSocket.create(this.secretKey);

  final Lock _lock = Lock();

  final TransferSecretKey secretKey;

  Future<void> close();

  void destroy();

  Future<void> flush();

  void add(List<int> data);

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
    return writePacketToSink(
      this,
      packet,
      hMacKey: secretKey.hMacKey,
      aesKey: secretKey.aesKey,
    );
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

  Future<void> addCommand(TransferDataCommand command) async {
    d('send command to remote: $command');
    await writePacketToSink(this, TransferCommandPacket(command),
        hMacKey: secretKey.hMacKey, aesKey: secretKey.aesKey);
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

  Future<void> addMessageMention(MessageMention messageMention) {
    var data = messageMention;
    if (messageMention.hasRead == null) {
      data = data.copyWith(hasRead: const Value(false));
    }
    final wrapper = JsonTransferData(
      data: data.toJson(),
      type: JsonTransferDataType.messageMention,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addApp(TransferDataApp app) {
    final wrapper = JsonTransferData(
      data: app.toJson(),
      type: JsonTransferDataType.app,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> _addTransferJson(JsonTransferData data) {
    final packet = TransferDataPacket(data);
    return writePacketToSink(this, packet,
        aesKey: secretKey.aesKey, hMacKey: secretKey.hMacKey);
  }
}

class _TransferSocket extends TransferSocket {
  _TransferSocket(this.socket, super.secretKey) : super.create();

  final Socket socket;

  @override
  Future<void> close() => _lock.synchronized(socket.close);

  @override
  void destroy() => socket.destroy();

  @override
  Future<void> flush() => _lock.synchronized(socket.flush);

  @override
  void add(List<int> data) => socket.add(data);
}
