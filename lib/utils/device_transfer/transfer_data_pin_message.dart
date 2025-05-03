import 'package:json_annotation/json_annotation.dart';

import '../../db/mixin_database.dart' as db;

part 'transfer_data_pin_message.g.dart';

@JsonSerializable()
class TransferDataPinMessage {
  TransferDataPinMessage({
    required this.messageId,
    required this.conversationId,
    required this.createdAt,
  });

  factory TransferDataPinMessage.fromJson(Map<String, dynamic> json) =>
      _$TransferDataPinMessageFromJson(json);

  factory TransferDataPinMessage.fromDbPinMessage(db.PinMessage data) =>
      TransferDataPinMessage(
        messageId: data.messageId,
        conversationId: data.conversationId,
        createdAt: data.createdAt,
      );

  @JsonKey(name: 'message_id')
  final String messageId;

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  db.PinMessage toDbPinMessage() => db.PinMessage(
    messageId: messageId,
    conversationId: conversationId,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => _$TransferDataPinMessageToJson(this);

  @override
  String toString() => 'TransferDataPinMessage($messageId)';
}
