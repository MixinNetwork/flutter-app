import 'package:json_annotation/json_annotation.dart';
import '../../db/mixin_database.dart' as db;

part 'transfer_data_sticker.g.dart';

@JsonSerializable()
class TransferDataSticker {
  TransferDataSticker({
    required this.stickerId,
    required this.name,
    required this.assetUrl,
    required this.assetType,
    required this.assetWidth,
    required this.assetHeight,
    required this.createdAt,
    this.albumId,
    this.lastUseAt,
  });

  factory TransferDataSticker.fromJson(Map<String, dynamic> json) =>
      _$TransferDataStickerFromJson(json);

  factory TransferDataSticker.fromDbSticker(db.Sticker s) =>
      TransferDataSticker(
        stickerId: s.stickerId,
        albumId: s.albumId,
        name: s.name,
        assetUrl: s.assetUrl,
        assetType: s.assetType,
        assetWidth: s.assetWidth,
        assetHeight: s.assetHeight,
        createdAt: s.createdAt,
        lastUseAt: s.lastUseAt,
      );

  @JsonKey(name: 'sticker_id')
  final String stickerId;

  @JsonKey(name: 'album_id')
  final String? albumId;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'asset_url')
  final String assetUrl;

  @JsonKey(name: 'asset_type')
  final String assetType;

  @JsonKey(name: 'asset_width')
  final int assetWidth;

  @JsonKey(name: 'asset_height')
  final int assetHeight;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'last_use_at')
  final DateTime? lastUseAt;

  Map<String, dynamic> toJson() => _$TransferDataStickerToJson(this);

  db.Sticker toDbSticker() => db.Sticker(
    stickerId: stickerId,
    albumId: albumId,
    name: name,
    assetUrl: assetUrl,
    assetType: assetType,
    assetWidth: assetWidth,
    assetHeight: assetHeight,
    createdAt: createdAt,
    lastUseAt: lastUseAt,
  );

  @override
  String toString() => 'TransferDataSticker($stickerId)';
}
