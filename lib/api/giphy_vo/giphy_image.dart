import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'giphy_image.g.dart';

@JsonSerializable()
class GiphyImage with EquatableMixin {
  GiphyImage({
    required this.url,
    required this.width,
    required this.height,
    required this.size,
    required this.mp4,
    required this.mp4Size,
    required this.webp,
    required this.webpSize,
  });

  factory GiphyImage.fromJson(Map<String, dynamic> json) =>
      _$GiphyImageFromJson(json);

  final String url;
  final int width;
  final int height;
  final int size;
  final String mp4;

  @JsonKey(name: 'mp4_size')
  final int mp4Size;

  final String webp;

  @JsonKey(name: 'webp_size')
  final int webpSize;

  Map<String, dynamic> toJson() => _$GiphyImageToJson(this);

  @override
  List<Object> get props =>
      [url, width, height, size, mp4, mp4Size, webp, webpSize];
}
