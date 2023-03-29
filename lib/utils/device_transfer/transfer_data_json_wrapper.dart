import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'transfer_conversation_data.dart';
import 'transfer_data.dart';
import 'transfer_message_data.dart';

part 'transfer_data_json_wrapper.g.dart';

const kTypeConversation = 'conversation';
const kTypeMessage = 'message';

extension SocketExtension on Socket {
  Future<void> addConversation(TransferConversationData conversation) {
    final wrapper = TransferDataJsonWrapper(
      data: conversation.toJson(),
      type: kTypeConversation,
    );
    return _addTransferJson(wrapper);
  }

  Future<void> addMessage(TransferMessageData message) {
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
