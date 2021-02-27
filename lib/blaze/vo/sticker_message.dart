import 'package:json_annotation/json_annotation.dart';

part 'sticker_message.g.dart';

@JsonSerializable()
class StickerMessage {
  StickerMessage(
    this.stickerId,
    this.albumId,
    this.name,
  );

  factory StickerMessage.fromJson(Map<String, dynamic> json) =>
      _$StickerMessageFromJson(json);

  @JsonKey(name: 'sticker_id')
  String stickerId;
  @JsonKey(name: 'album_id')
  String? albumId;
  @JsonKey(name: 'name')
  String? name;

  Map<String, dynamic> toJson() => _$StickerMessageToJson(this);
}
