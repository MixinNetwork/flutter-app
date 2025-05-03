// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_pin_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataPinMessage _$TransferDataPinMessageFromJson(
  Map<String, dynamic> json,
) => TransferDataPinMessage(
  messageId: json['message_id'] as String,
  conversationId: json['conversation_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$TransferDataPinMessageToJson(
  TransferDataPinMessage instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'conversation_id': instance.conversationId,
  'created_at': instance.createdAt.toIso8601String(),
};
