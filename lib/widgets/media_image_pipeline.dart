import 'dart:async';
import 'dart:io';
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

/// [image] decoded at the smallest size that covers [box].
///
/// A photo decodes to tens of megabytes at full size, and the raster thread
/// uploads all of it, which stalls a frame that shows a few of them. Each side
/// of the box goes up in steps of 64 pixels, so a window resize decodes again
/// only now and then.
ImageProvider coverDecodeImage(
  ImageProvider image, {
  required Size box,
  required double devicePixelRatio,
}) {
  if (!box.isFinite || box.isEmpty) return image;
  int step(double side) => (side * devicePixelRatio / 64).ceil() * 64;
  return CoverResizeImage(
    image,
    width: step(box.width),
    height: step(box.height),
  );
}

/// [imageProvider] decoded at the smallest size, with its aspect ratio, that
/// covers [width] x [height], and never above its own size.
///
/// The decoder gives the size after the EXIF rotation, so a rotated photo
/// covers the box too. [ResizeImagePolicy.fit] with [BoxFit.cover] decodes
/// too small, and a bound of the long side decodes too large.
// shortcut: ResizeImage has no cover policy yet, use ResizeImagePolicy.cover
// when flutter/flutter#61987 lands.
@immutable
class CoverResizeImage extends ImageProvider<CoverResizeImageKey> {
  const CoverResizeImage(
    this.imageProvider, {
    required this.width,
    required this.height,
  });

  final ImageProvider imageProvider;
  final int width;
  final int height;

  @override
  Future<CoverResizeImageKey> obtainKey(ImageConfiguration configuration) =>
      imageProvider
          .obtainKey(configuration)
          .then((key) => CoverResizeImageKey(key, width, height));

  @override
  ImageStreamCompleter loadImage(
    CoverResizeImageKey key,
    ImageDecoderCallback decode,
  ) {
    Future<ui.Codec> decodeCover(
      ui.ImmutableBuffer buffer, {
      ui.TargetImageSizeCallback? getTargetSize,
    }) {
      assert(getTargetSize == null);
      return decode(
        buffer,
        getTargetSize: (intrinsicWidth, intrinsicHeight) {
          // The side that needs the larger scale sets it; the other side
          // rounds up so that it still covers the box.
          final widthCovers =
              width * intrinsicHeight >= height * intrinsicWidth;
          final targetWidth = widthCovers
              ? width
              : (height * intrinsicWidth + intrinsicHeight - 1) ~/
                    intrinsicHeight;
          final targetHeight = widthCovers
              ? (width * intrinsicHeight + intrinsicWidth - 1) ~/ intrinsicWidth
              : height;
          if (targetWidth >= intrinsicWidth) return const ui.TargetImageSize();
          return ui.TargetImageSize(width: targetWidth, height: targetHeight);
        },
      );
    }

    return imageProvider.loadImage(key.providerCacheKey, decodeCover);
  }

  @override
  bool operator ==(Object other) =>
      other is CoverResizeImage &&
      other.imageProvider == imageProvider &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(imageProvider, width, height);
}

@immutable
class CoverResizeImageKey {
  const CoverResizeImageKey(this.providerCacheKey, this.width, this.height);

  final Object providerCacheKey;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      other is CoverResizeImageKey &&
      other.providerCacheKey == providerCacheKey &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(providerCacheKey, width, height);
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
        // A new image resets the frame, while gapless playback still paints
        // the old one until the new one loads.
        final image = child is Semantics ? child.child : child;
        final painting = image is RawImage && image.image != null;
        if (wasSynchronouslyLoaded || frame != null || painting) return child;
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
  // The child stays at the same place in the tree after the check, so a new
  // decode size of a checked file keeps the image state and its last frame.
  var _ready = true;
  Future<void>? _pending;

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
    _pending = null;
    _ready = true;
    // A message image decodes at its display size through CoverResizeImage.
    final image = switch (widget.image) {
      CoverResizeImage(:final imageProvider) => imageProvider,
      final image => image,
    };
    if (image is! FileImage) return;
    final filePathSegments = image.file.uri.pathSegments;
    final fileName = filePathSegments.isEmpty
        ? ''
        : filePathSegments.last.toLowerCase();
    if (fileName.isEmpty) return;
    if (!fileName.endsWith('.gif') && fileName.contains('.')) return;

    final path = image.file.absolute.path;
    if (_checkedImageFiles.contains(path)) return;

    _ready = false;
    final pending = _pending = _normalize(image.file, widget.image);
    unawaited(
      pending.catchError((Object _) {}).whenComplete(() {
        if (!mounted || !identical(_pending, pending)) return;
        setState(() => _ready = true);
      }),
    );
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
  Widget build(BuildContext context) =>
      _ready ? widget.childBuilder() : widget.placeholder();
}
