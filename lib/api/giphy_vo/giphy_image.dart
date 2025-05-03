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

  @JsonKey(name: 'url', defaultValue: '')
  final String url;
  @JsonKey(name: 'width', defaultValue: '0')
  final String width;
  @JsonKey(name: 'height', defaultValue: '0')
  final String height;
  final String? size;
  final String? mp4;

  @JsonKey(name: 'mp4_size')
  final String? mp4Size;

  final String? webp;

  @JsonKey(name: 'webp_size')
  final String? webpSize;

  Map<String, dynamic> toJson() => _$GiphyImageToJson(this);

  @override
  List<Object?> get props => [
    url,
    width,
    height,
    size,
    mp4,
    mp4Size,
    webp,
    webpSize,
  ];
}
