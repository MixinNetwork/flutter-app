import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'giphy_image.dart';

part 'giphy_image_set.g.dart';

@JsonSerializable()
class GiphyImageSet with EquatableMixin {
  GiphyImageSet({
    required this.fixedHeight,
    required this.fixedHeightStill,
    required this.fixedHeightDownsampled,
    required this.fixedWidth,
    required this.fixedWidthStill,
    required this.fixedWidthDownsampled,
    required this.fixedHeightSmall,
    required this.fixedHeightSmallStill,
    required this.fixedWidthSmall,
    required this.fixedWidthSmallStill,
    required this.downsized,
    required this.downsizedStill,
    required this.downsizedLarge,
    required this.original,
    required this.originalStill,
  });

  factory GiphyImageSet.fromJson(Map<String, dynamic> json) =>
      _$GiphyImageSetFromJson(json);

  @JsonKey(name: 'fixed_height')
  final GiphyImage fixedHeight;

  @JsonKey(name: 'fixed_height_still')
  final GiphyImage fixedHeightStill;

  @JsonKey(name: 'fixed_height_downsampled')
  final GiphyImage fixedHeightDownsampled;

  @JsonKey(name: 'fixed_width')
  final GiphyImage fixedWidth;

  @JsonKey(name: 'fixed_width_still')
  final GiphyImage fixedWidthStill;

  @JsonKey(name: 'fixed_width_downsampled')
  final GiphyImage fixedWidthDownsampled;

  @JsonKey(name: 'fixed_height_small')
  final GiphyImage fixedHeightSmall;

  @JsonKey(name: 'fixed_height_small_still')
  final GiphyImage fixedHeightSmallStill;

  @JsonKey(name: 'fixed_width_small')
  final GiphyImage fixedWidthSmall;

  @JsonKey(name: 'fixed_width_small_still')
  final GiphyImage fixedWidthSmallStill;

  @JsonKey(name: 'downsized')
  final GiphyImage downsized;

  @JsonKey(name: 'downsized_still')
  final GiphyImage downsizedStill;

  @JsonKey(name: 'downsized_large')
  final GiphyImage downsizedLarge;

  @JsonKey(name: 'original')
  final GiphyImage original;

  @JsonKey(name: 'original_still')
  final GiphyImage originalStill;

  @override
  List<Object?> get props => [
    fixedHeight,
    fixedHeightStill,
    fixedHeightDownsampled,
    fixedWidth,
    fixedWidthStill,
    fixedWidthDownsampled,
    fixedHeightSmall,
    fixedHeightSmallStill,
    fixedWidthSmall,
    fixedWidthSmallStill,
    downsized,
    downsizedStill,
    downsizedLarge,
    original,
    originalStill,
  ];

  Map<String, dynamic> toJson() => _$GiphyImageSetToJson(this);
}
