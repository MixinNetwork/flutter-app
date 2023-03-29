import 'package:json_annotation/json_annotation.dart';

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

  @override
  String toString() => 'TransferDataSticker($stickerId)';
}
