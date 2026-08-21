import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/image.dart';
import '../utils/proxy.dart';
import 'global_image_cache.dart';

typedef PlaceholderWidgetBuilder = Widget Function();

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
    final image = this.image;
    if (image is NetworkImage) {
      return CachedMediaImage(
        url: image.url,
        scale: image.scale,
        proxyConfig: proxyConfig,
        placeholder: placeholder,
        errorBuilder: errorBuilder,
        width: width,
        height: height,
        fit: fit,
        isAntiAlias: isAntiAlias,
      );
    }

    Widget fallback() =>
        placeholder?.call() ?? SizedBox(width: width, height: height);

    Widget imageView() => Image(
      image: image,
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
      image: image,
      placeholder: fallback,
      childBuilder: imageView,
    );
  }
}

class CachedMediaImage extends StatefulWidget {
  const CachedMediaImage({
    required this.url,
    required this.scale,
    required this.proxyConfig,
    required this.placeholder,
    required this.errorBuilder,
    required this.width,
    required this.height,
    required this.fit,
    required this.isAntiAlias,
    @visibleForTesting this.imageCache,
    super.key,
  });

  final String url;
  final double scale;
  final ProxyConfig? proxyConfig;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isAntiAlias;

  @visibleForTesting
  final GlobalImageCache? imageCache;

  @override
  State<CachedMediaImage> createState() => _CachedMediaImageState();
}

class _CachedMediaImageState extends State<CachedMediaImage> {
  late Stream<Uint8List> _images;

  @override
  void initState() {
    super.initState();
    _images = _imageStream();
  }

  @override
  void didUpdateWidget(covariant CachedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.proxyConfig != widget.proxyConfig ||
        oldWidget.imageCache != widget.imageCache) {
      _images = _imageStream();
    }
  }

  GlobalImageCache get _cache => widget.imageCache ?? GlobalImageCache.instance;

  Stream<Uint8List> _imageStream() => _cache.getBytes(
    widget.url,
    proxyConfig: widget.proxyConfig,
    limitBytes: true,
  );

  @override
  Widget build(BuildContext context) {
    Widget fallback() =>
        widget.placeholder?.call() ??
        SizedBox(width: widget.width, height: widget.height);

    return StreamBuilder<Uint8List>(
      key: ValueKey((widget.url, widget.proxyConfig, widget.imageCache)),
      initialData: _cache.peekMemoryBytes(
        widget.url,
        proxyConfig: widget.proxyConfig,
      ),
      stream: _images,
      builder: (context, snapshot) {
        final error = snapshot.error;
        if (error != null) {
          return widget.errorBuilder?.call(context, error, StackTrace.empty) ??
              fallback();
        }
        final bytes = snapshot.data;
        if (bytes == null) return fallback();

        return Image.memory(
          bytes,
          scale: widget.scale,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          isAntiAlias: widget.isAntiAlias,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return fallback();
          },
          errorBuilder: (context, error, stackTrace) =>
              widget.errorBuilder?.call(context, error, stackTrace) ??
              fallback(),
        );
      },
    );
  }
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
