// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'giphy_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GiphyImage _$GiphyImageFromJson(Map<String, dynamic> json) => GiphyImage(
      url: json['url'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      size: json['size'] as int,
      mp4: json['mp4'] as String,
      mp4Size: json['mp4_size'] as int,
      webp: json['webp'] as String,
      webpSize: json['webp_size'] as int,
    );

Map<String, dynamic> _$GiphyImageToJson(GiphyImage instance) =>
    <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'size': instance.size,
      'mp4': instance.mp4,
      'mp4_size': instance.mp4Size,
      'webp': instance.webp,
      'webp_size': instance.webpSize,
    };
