// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'giphy_gif.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GiphyGif _$GiphyGifFromJson(Map<String, dynamic> json) => GiphyGif(
      id: json['id'] as String,
      type: json['type'] as String,
      images: GiphyImageSet.fromJson(json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GiphyGifToJson(GiphyGif instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'images': instance.images.toJson(),
    };
