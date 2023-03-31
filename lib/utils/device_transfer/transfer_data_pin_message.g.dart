// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_pin_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataPinMessage _$TransferDataPinMessageFromJson(
        Map<String, dynamic> json) =>
    TransferDataPinMessage(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TransferDataPinMessageToJson(
        TransferDataPinMessage instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'conversationId': instance.conversationId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
