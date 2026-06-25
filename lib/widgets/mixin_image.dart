import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../utils/extension/extension.dart';
import 'media_image_pipeline.dart';

class MixinImage extends StatelessWidget {
  const MixinImage({
    required this.image,
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
    this.normalizeGif = false,
  });

  MixinImage.network(
    String url, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
    this.normalizeGif = false,
  }) : image = NetworkImage(url);

  MixinImage.file(
    File file, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : image = FileImage(file),
       normalizeGif = false;

  MixinImage.asset(
    String assetName, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : image = AssetImage(assetName),
       normalizeGif = false;

  MixinImage.memory(
    Uint8List bytes, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : image = MemoryImage(bytes),
       normalizeGif = false;

  final ImageProvider image;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isAntiAlias;
  final bool normalizeGif;

  @override
  Widget build(BuildContext context) => MediaImagePipeline(
    image: image,
    proxyConfig: context.database.settingProperties.activatedProxy,
    placeholder: placeholder,
    errorBuilder: errorBuilder,
    width: width,
    height: height,
    fit: fit,
    isAntiAlias: isAntiAlias,
    normalizeGif: normalizeGif,
  );
}
