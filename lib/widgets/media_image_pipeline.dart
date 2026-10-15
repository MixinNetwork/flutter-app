import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/image.dart';
import '../utils/proxy.dart';
import 'global_image_cache.dart';

typedef PlaceholderWidgetBuilder = Widget Function();

ImageProvider resolveMediaImageProvider(
  ImageProvider image,
  ProxyConfig? proxyConfig,
) => image is NetworkImage
    ? CachedNetworkImage(
        image.url,
        scale: image.scale,
        proxyConfig: proxyConfig,
      )
    : image;

/// [image] decoded at a size that covers [box], for an image of
/// [mediaWidth] x [mediaHeight].
///
/// A photo decodes to tens of megabytes at full size, and the raster thread
/// uploads all of it, which stalls a frame that shows a few of them. The short
/// side of the decoded image covers the long side of the box, so the result
/// does not depend on whether the stored size is before or after the EXIF
/// rotation. The size goes up in steps of 64 pixels, so a window resize
/// decodes again only now and then.
ImageProvider coverDecodeImage(
  ImageProvider image, {
  required Size box,
  required int? mediaWidth,
  required int? mediaHeight,
  required double devicePixelRatio,
}) {
  if (mediaWidth == null ||
      mediaHeight == null ||
      mediaWidth <= 0 ||
      mediaHeight <= 0 ||
      !box.isFinite ||
      box.isEmpty) {
    return image;
  }
  final short = math.min(mediaWidth, mediaHeight);
  final long = math.max(mediaWidth, mediaHeight);
  final side = (box.longestSide * devicePixelRatio / 64).ceil() * 64;
  if (side >= short) return image;
  final bound = (side * long / short).ceil();
  return ResizeImage(
    image,
    width: bound,
    height: bound,
    policy: ResizeImagePolicy.fit,
  );
}

final _checkedImageFiles = <String>{};

class MediaImagePipeline extends StatelessWidget {
  const MediaImagePipeline({
    required this.image,
    super.key,
    this.proxyConfig,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
    this.gaplessPlayback = false,
  });

  final ImageProvider image;
  final ProxyConfig? proxyConfig;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isAntiAlias;

  /// Whether a new [image] keeps showing the old one until it loads.
  final bool gaplessPlayback;

  @override
  Widget build(BuildContext context) {
    final resolvedImage = resolveMediaImageProvider(image, proxyConfig);
    Widget fallback() =>
        placeholder?.call() ?? SizedBox(width: width, height: height);

    Widget imageView() => Image(
      image: resolvedImage,
      width: width,
      height: height,
      fit: fit,
      isAntiAlias: isAntiAlias,
      gaplessPlayback: gaplessPlayback,
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
}

@immutable
class CachedNetworkImage extends ImageProvider<CachedNetworkImage> {
  const CachedNetworkImage(
    this.url, {
    this.scale = 1.0,
    this.proxyConfig,
    @visibleForTesting this.imageCache,
  });

  final String url;
  final double scale;
  final ProxyConfig? proxyConfig;

  @visibleForTesting
  final GlobalImageCache? imageCache;

  GlobalImageCache get _cache => imageCache ?? GlobalImageCache.instance;

  @override
  Future<CachedNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<CachedNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    CachedNetworkImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _loadAsync(key, decode),
    scale: key.scale,
    debugLabel: key.url,
    informationCollector: () => <DiagnosticsNode>[
      DiagnosticsProperty<ImageProvider>('Image provider', this),
      DiagnosticsProperty<CachedNetworkImage>('Image key', key),
    ],
  );

  Future<ui.Codec> _loadAsync(
    CachedNetworkImage key,
    Future<ui.Codec> Function(ui.ImmutableBuffer buffer) decode,
  ) async {
    try {
      // ponytail: expired entries revalidate before decode; add a streaming
      // completer only if live stale-while-revalidate updates are required.
      final bytes = await _cache
          .getBytes(
            key.url,
            proxyConfig: key.proxyConfig,
            limitBytes: true,
          )
          .last;
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CachedNetworkImage &&
      other.url == url &&
      other.scale == scale &&
      other.proxyConfig == proxyConfig &&
      other.imageCache == imageCache;

  @override
  int get hashCode => Object.hash(url, scale, proxyConfig, imageCache);
}

class NormalizedGifImageGate extends StatefulWidget {
  const NormalizedGifImageGate({
    required this.image,
    required this.placeholder,
    required this.childBuilder,
    super.key,
  });

  final ImageProvider image;
  final Widget Function() placeholder;
  final Widget Function() childBuilder;

  @override
  State<NormalizedGifImageGate> createState() => _NormalizedGifImageGateState();
}

class _NormalizedGifImageGateState extends State<NormalizedGifImageGate> {
  Future<void>? _future;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant NormalizedGifImageGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _start();
    }
  }

  void _start() {
    // A message image decodes at its display size through a ResizeImage.
    final image = switch (widget.image) {
      ResizeImage(:final imageProvider) => imageProvider,
      final image => image,
    };
    if (image is! FileImage) {
      _future = null;
      return;
    }
    final filePathSegments = image.file.uri.pathSegments;
    final fileName = filePathSegments.isEmpty
        ? ''
        : filePathSegments.last.toLowerCase();
    if (fileName.isEmpty) {
      _future = null;
      return;
    }
    if (!fileName.endsWith('.gif') && fileName.contains('.')) {
      _future = null;
      return;
    }

    final path = image.file.absolute.path;
    if (_checkedImageFiles.contains(path)) {
      _future = null;
      return;
    }

    _future = _normalize(image.file, widget.image);
  }

  Future<void> _normalize(File file, ImageProvider shown) async {
    try {
      await normalizeGifFileIfNeeded(file, null);
      await FileImage(file).evict();
      await shown.evict();
    } finally {
      _checkedImageFiles.add(file.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return widget.childBuilder();

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return widget.childBuilder();
        }
        return widget.placeholder();
      },
    );
  }
}
