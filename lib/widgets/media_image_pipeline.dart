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
  });

  final ImageProvider image;
  final ProxyConfig? proxyConfig;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isAntiAlias;

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
    final image = widget.image;
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

    _future = _normalize(image.file);
  }

  Future<void> _normalize(File file) async {
    try {
      await normalizeGifFileIfNeeded(file, null);
      await FileImage(file).evict();
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
