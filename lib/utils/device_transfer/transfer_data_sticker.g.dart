// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_sticker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataSticker _$TransferDataStickerFromJson(Map<String, dynamic> json) =>
    TransferDataSticker(
      stickerId: json['sticker_id'] as String,
      name: json['name'] as String,
      assetUrl: json['asset_url'] as String,
      assetType: json['asset_type'] as String,
      assetWidth: (json['asset_width'] as num).toInt(),
      assetHeight: (json['asset_height'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      albumId: json['album_id'] as String?,
      lastUseAt: json['last_use_at'] == null
          ? null
          : DateTime.parse(json['last_use_at'] as String),
    );

Map<String, dynamic> _$TransferDataStickerToJson(
        TransferDataSticker instance) =>
    <String, dynamic>{
      'sticker_id': instance.stickerId,
      'album_id': instance.albumId,
      'name': instance.name,
      'asset_url': instance.assetUrl,
      'asset_type': instance.assetType,
      'asset_width': instance.assetWidth,
      'asset_height': instance.assetHeight,
      'created_at': instance.createdAt.toIso8601String(),
      'last_use_at': instance.lastUseAt?.toIso8601String(),
    };
