// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentMessage _$AttachmentMessageFromJson(Map<String, dynamic> json) {
  return AttachmentMessage(
    json['key'],
    json['digest'],
    json['attachment_id'] as String,
    json['mime_type'] as String,
    json['size'] as int,
    json['name'] as String?,
    json['width'] as int?,
    json['height'] as int?,
    json['thumbnail'] as String?,
    json['duration'] as int?,
    json['waveform'],
    json['caption'] as String?,
    json['created_at'] as String?,
  );
}

Map<String, dynamic> _$AttachmentMessageToJson(AttachmentMessage instance) =>
    <String, dynamic>{
      'key': dynamicToJson(instance.key),
      'digest': dynamicToJson(instance.digest),
      'attachment_id': instance.attachmentId,
      'mime_type': instance.mimeType,
      'size': instance.size,
      'name': instance.name,
      'width': instance.width,
      'height': instance.height,
      'thumbnail': instance.thumbnail,
      'duration': instance.duration,
      'waveform': dynamicToJson(instance.waveform),
      'caption': instance.caption,
      'created_at': instance.createdAt,
    };
