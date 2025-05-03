// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'giphy_image_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GiphyImageSet _$GiphyImageSetFromJson(Map<String, dynamic> json) =>
    GiphyImageSet(
      fixedHeight:
          GiphyImage.fromJson(json['fixed_height'] as Map<String, dynamic>),
      fixedHeightStill: GiphyImage.fromJson(
          json['fixed_height_still'] as Map<String, dynamic>),
      fixedHeightDownsampled: GiphyImage.fromJson(
          json['fixed_height_downsampled'] as Map<String, dynamic>),
      fixedWidth:
          GiphyImage.fromJson(json['fixed_width'] as Map<String, dynamic>),
      fixedWidthStill: GiphyImage.fromJson(
          json['fixed_width_still'] as Map<String, dynamic>),
      fixedWidthDownsampled: GiphyImage.fromJson(
          json['fixed_width_downsampled'] as Map<String, dynamic>),
      fixedHeightSmall: GiphyImage.fromJson(
          json['fixed_height_small'] as Map<String, dynamic>),
      fixedHeightSmallStill: GiphyImage.fromJson(
          json['fixed_height_small_still'] as Map<String, dynamic>),
      fixedWidthSmall: GiphyImage.fromJson(
          json['fixed_width_small'] as Map<String, dynamic>),
      fixedWidthSmallStill: GiphyImage.fromJson(
          json['fixed_width_small_still'] as Map<String, dynamic>),
      downsized: GiphyImage.fromJson(json['downsized'] as Map<String, dynamic>),
      downsizedStill:
          GiphyImage.fromJson(json['downsized_still'] as Map<String, dynamic>),
      downsizedLarge:
          GiphyImage.fromJson(json['downsized_large'] as Map<String, dynamic>),
      original: GiphyImage.fromJson(json['original'] as Map<String, dynamic>),
      originalStill:
          GiphyImage.fromJson(json['original_still'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GiphyImageSetToJson(GiphyImageSet instance) =>
    <String, dynamic>{
      'fixed_height': instance.fixedHeight.toJson(),
      'fixed_height_still': instance.fixedHeightStill.toJson(),
      'fixed_height_downsampled': instance.fixedHeightDownsampled.toJson(),
      'fixed_width': instance.fixedWidth.toJson(),
      'fixed_width_still': instance.fixedWidthStill.toJson(),
      'fixed_width_downsampled': instance.fixedWidthDownsampled.toJson(),
      'fixed_height_small': instance.fixedHeightSmall.toJson(),
      'fixed_height_small_still': instance.fixedHeightSmallStill.toJson(),
      'fixed_width_small': instance.fixedWidthSmall.toJson(),
      'fixed_width_small_still': instance.fixedWidthSmallStill.toJson(),
      'downsized': instance.downsized.toJson(),
      'downsized_still': instance.downsizedStill.toJson(),
      'downsized_large': instance.downsizedLarge.toJson(),
      'original': instance.original.toJson(),
      'original_still': instance.originalStill.toJson(),
    };
