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

  final String stickerId;
  final String? albumId;
  final String name;
  final String assetUrl;
  final String assetType;
  final int assetWidth;
  final int assetHeight;
  final DateTime createdAt;
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
