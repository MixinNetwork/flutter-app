import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../utils/extension/extension.dart';
import 'media_image_pipeline.dart';

typedef PlaceholderWidgetBuilder = Widget Function();

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
  Widget build(BuildContext context) {
    final resolvedImage = _resolveImage(context);

    Widget fallback() =>
        placeholder?.call() ?? SizedBox(width: width, height: height);

    Widget imageView() => Image(
      image: resolvedImage,
      width: width,
      height: height,
      fit: fit,
      isAntiAlias: isAntiAlias,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return fallback();
      },
      errorBuilder: (context, error, stackTrace) =>
          errorBuilder?.call(context, error, stackTrace) ?? fallback(),
    );

    return NormalizedGifImageGate(
      image: resolvedImage,
      placeholder: fallback,
      childBuilder: imageView,
    );
  }

  ImageProvider _resolveImage(BuildContext context) {
    final image = this.image;
    final proxyConfig = context.database.settingProperties.activatedProxy;
    if (image is NetworkImage &&
        shouldUseMediaImagePipeline(
          image.url,
          proxyConfig,
          normalizeGif: normalizeGif,
        )) {
      return ProxyNetworkImage(
        image.url,
        scale: image.scale,
        proxyConfig: proxyConfig,
      );
    }
    return image;
  }
}
