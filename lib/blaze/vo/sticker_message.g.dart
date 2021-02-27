// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sticker_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StickerMessage _$StickerMessageFromJson(Map<String, dynamic> json) {
  return StickerMessage(
    json['sticker_id'] as String,
    json['album_id'] as String?,
    json['name'] as String?,
  );
}

Map<String, dynamic> _$StickerMessageToJson(StickerMessage instance) =>
    <String, dynamic>{
      'sticker_id': instance.stickerId,
      'album_id': instance.albumId,
      'name': instance.name,
    };
