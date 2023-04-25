import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide JsonKey;
import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart';
import '../logger.dart';
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

part 'json_transfer_data.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum JsonTransferDataType {
  conversation,
  message,
  sticker,
  asset,
  snapshot,
  user,
  expiredMessage,
  transcriptMessage,
  participant,
  pinMessage,
  messageMention,
  app,
  unknown;
}

@JsonSerializable()
class JsonTransferData {
  JsonTransferData({
    required this.data,
    required this.type,
  });

  factory JsonTransferData.fromJson(Map<String, dynamic> json) =>
      _$JsonTransferDataFromJson(json);

  final Map<String, dynamic> data;

  @JsonKey(unknownEnumValue: JsonTransferDataType.unknown)
  final JsonTransferDataType type;

  Map<String, dynamic> toJson() => _$JsonTransferDataToJson(this);
}

extension SocketExtension on IOSink {
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

  Future<void> addCommand(TransferDataCommand command) async {
    d('send command to remote: $command');
    await writePacketToSink(this, TransferCommandPacket(command));
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

  Future<void> _addTransferJson(JsonTransferData data) =>
      writePacketToSink(this, TransferDataPacket(data));
}
