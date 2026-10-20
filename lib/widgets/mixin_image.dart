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
    this.gaplessPlayback = false,
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
  }) : gaplessPlayback = false,
       image = NetworkImage(url);

  MixinImage.file(
    File file, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : gaplessPlayback = false,
       image = FileImage(file);

  MixinImage.asset(
    String assetName, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : gaplessPlayback = false,
       image = AssetImage(assetName);

  MixinImage.memory(
    Uint8List bytes, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : gaplessPlayback = false,
       image = MemoryImage(bytes);

  final ImageProvider image;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isAntiAlias;
  final bool gaplessPlayback;

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
    gaplessPlayback: gaplessPlayback,
  );
}
