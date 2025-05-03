import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'giphy_image_set.dart';

part 'giphy_gif.g.dart';

@JsonSerializable()
class GiphyGif with EquatableMixin {
  GiphyGif({required this.id, required this.type, required this.images});

  factory GiphyGif.fromJson(Map<String, dynamic> json) =>
      _$GiphyGifFromJson(json);

  final String id;

  final String type;

  final GiphyImageSet images;

  @override
  List<Object?> get props => [id, type, images];

  Map<String, dynamic> toJson() => _$GiphyGifToJson(this);
}
