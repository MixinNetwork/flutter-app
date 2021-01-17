// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveMessage _$LiveMessageFromJson(Map<String, dynamic> json) {
  return LiveMessage(
    json['width'] as int,
    json['height'] as int,
    json['thumb_url'] as String,
    json['url'] as String,
  );
}

Map<String, dynamic> _$LiveMessageToJson(LiveMessage instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'thumb_url': instance.thumbUrl,
      'url': instance.url,
    };
