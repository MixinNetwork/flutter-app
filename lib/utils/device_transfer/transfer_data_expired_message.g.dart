// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_expired_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataExpiredMessage _$TransferDataExpiredMessageFromJson(
        Map<String, dynamic> json) =>
    TransferDataExpiredMessage(
      messageId: json['message_id'] as String,
      expireIn: json['expire_in'] as int,
      expireAt: json['expire_at'] as int?,
    );

Map<String, dynamic> _$TransferDataExpiredMessageToJson(
        TransferDataExpiredMessage instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'expire_in': instance.expireIn,
      'expire_at': instance.expireAt,
    };
