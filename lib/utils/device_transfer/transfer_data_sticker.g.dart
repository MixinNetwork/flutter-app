// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_data_sticker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferDataSticker _$TransferDataStickerFromJson(Map<String, dynamic> json) =>
    TransferDataSticker(
      stickerId: json['stickerId'] as String,
      name: json['name'] as String,
      assetUrl: json['assetUrl'] as String,
      assetType: json['assetType'] as String,
      assetWidth: json['assetWidth'] as int,
      assetHeight: json['assetHeight'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      albumId: json['albumId'] as String?,
      lastUseAt: json['lastUseAt'] == null
          ? null
          : DateTime.parse(json['lastUseAt'] as String),
    );

Map<String, dynamic> _$TransferDataStickerToJson(
        TransferDataSticker instance) =>
    <String, dynamic>{
      'stickerId': instance.stickerId,
      'albumId': instance.albumId,
      'name': instance.name,
      'assetUrl': instance.assetUrl,
      'assetType': instance.assetType,
      'assetWidth': instance.assetWidth,
      'assetHeight': instance.assetHeight,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUseAt': instance.lastUseAt?.toIso8601String(),
    };
