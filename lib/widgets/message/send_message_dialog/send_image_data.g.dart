// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_image_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendImageData _$SendImageDataFromJson(Map<String, dynamic> json) =>
    SendImageData(
      url: json['url'] as String,
      attachmentExtra: json['attachment_extra'] == null
          ? null
          : AttachmentExtra.fromJson(
              json['attachment_extra'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SendImageDataToJson(SendImageData instance) =>
    <String, dynamic>{
      'url': instance.url,
      'attachment_extra': instance.attachmentExtra?.toJson(),
    };
