// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_message_minimal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinMessageMinimal _$PinMessageMinimalFromJson(Map<String, dynamic> json) =>
    PinMessageMinimal(
      messageId: json['message_id'] as String,
      type: json['category'] as String,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$PinMessageMinimalToJson(PinMessageMinimal instance) =>
    <String, dynamic>{
      'message_id': instance.messageId,
      'category': instance.type,
      'content': instance.content,
    };
