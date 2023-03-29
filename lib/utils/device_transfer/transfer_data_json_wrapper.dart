import 'dart:io';

import 'package:flutter_app/utils/device_transfer/transfer_data_user.dart';
import 'package:json_annotation/json_annotation.dart';

import 'transfer_data_asset.dart';
import 'transfer_data_conversation.dart';
import 'transfer_data_message.dart';
import 'transfer_data_snapshot.dart';
import 'transfer_data_sticker.dart';
import 'transfer_protocol.dart';

part 'transfer_data_json_wrapper.g.dart';

const kTypeConversation = 'conversation';
const kTypeMessage = 'message';
const kTypeSticker = 'sticker';
const kTypeAsset = 'asset';
const kTypeSnapshot = 'snapshot';
const kTypeUser = 'user';

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

  Future<void> _addTransferJson(TransferDataJsonWrapper data) =>
      writePacketToSink(this, TransferJsonPacket(data));
}

@JsonSerializable()
class TransferDataJsonWrapper {
  TransferDataJsonWrapper({
    required this.data,
    required this.type,
  });

  factory TransferDataJsonWrapper.fromJson(Map<String, dynamic> json) =>
      _$TransferDataJsonWrapperFromJson(json);

  final Map<String, dynamic> data;
  final String type;

  Map<String, dynamic> toJson() => _$TransferDataJsonWrapperToJson(this);
}
