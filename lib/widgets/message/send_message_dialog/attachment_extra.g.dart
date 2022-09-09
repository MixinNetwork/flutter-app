// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_extra.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentExtra _$AttachmentExtraFromJson(Map<String, dynamic> json) =>
    AttachmentExtra(
      attachmentId: json['attachment_id'] as String,
      messageId: json['message_id'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$AttachmentExtraToJson(AttachmentExtra instance) =>
    <String, dynamic>{
      'attachment_id': instance.attachmentId,
      'message_id': instance.messageId,
      'created_at': instance.createdAt,
    };
