import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/extension/extension.dart';
import '../utils/image.dart';
import '../utils/proxy.dart';

typedef PlaceholderWidgetBuilder = Widget Function();

final _normalizedGifFiles = <String>{};

@immutable
class ProxyNetworkImage extends ImageProvider<ProxyNetworkImage> {
  const ProxyNetworkImage(this.url, {this.scale = 1.0, this.proxyConfig});

  final String url;
  final double scale;
  final ProxyConfig? proxyConfig;

  @override
  Future<ProxyNetworkImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<ProxyNetworkImage>(this);

  @override
  ImageStreamCompleter loadImage(
    ProxyNetworkImage key,
    ImageDecoderCallback decode,
  ) => _load(key, (buffer) => decode(buffer));

  ImageStreamCompleter _load(
    ProxyNetworkImage key,
    Future<ui.Codec> Function(ui.ImmutableBuffer buffer) decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _loadAsync(key, decode),
    scale: key.scale,
    debugLabel: key.url,
    informationCollector: () => <DiagnosticsNode>[
      DiagnosticsProperty<ImageProvider>('Image provider', this),
      DiagnosticsProperty<ProxyNetworkImage>('Image key', key),
    ],
  );

  Future<ui.Codec> _loadAsync(
    ProxyNetworkImage key,
    Future<ui.Codec> Function(ui.ImmutableBuffer buffer) decode,
  ) async {
    try {
      final bytes = normalizeGifBytesIfNeeded(
        await downloadImageBytes(key.url, proxyConfig: key.proxyConfig),
      );
      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ProxyNetworkImage &&
      other.url == url &&
      other.scale == scale &&
      other.proxyConfig == proxyConfig;

  @override
  int get hashCode => Object.hash(url, scale, proxyConfig);
}

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
  }) : image = FileImage(file);

  MixinImage.asset(
    String assetName, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : image = AssetImage(assetName);

  MixinImage.memory(
    Uint8List bytes, {
    super.key,
    this.placeholder,
    this.errorBuilder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isAntiAlias = false,
  }) : image = MemoryImage(bytes);

  final ImageProvider image;
  final PlaceholderWidgetBuilder? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isAntiAlias;

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

    return _LazyNormalizedGif(
      image: resolvedImage,
      placeholder: fallback,
      childBuilder: imageView,
    );
  }

  ImageProvider _resolveImage(BuildContext context) {
    final image = this.image;
    final proxyConfig = context.database.settingProperties.activatedProxy;
    if (image is NetworkImage) {
      return ProxyNetworkImage(
        image.url,
        scale: image.scale,
        proxyConfig: proxyConfig,
      );
    }
    return image;
  }
}

class _LazyNormalizedGif extends StatefulWidget {
  const _LazyNormalizedGif({
    required this.image,
    required this.placeholder,
    required this.childBuilder,
  });

  final ImageProvider image;
  final Widget Function() placeholder;
  final Widget Function() childBuilder;

  @override
  State<_LazyNormalizedGif> createState() => _LazyNormalizedGifState();
}

class _LazyNormalizedGifState extends State<_LazyNormalizedGif> {
  Future<void>? _future;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant _LazyNormalizedGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _start();
    }
  }

  void _start() {
    final image = widget.image;
    if (image is! FileImage ||
        !image.file.path.toLowerCase().endsWith('.gif')) {
      _future = null;
      return;
    }

    final path = image.file.absolute.path;
    if (_normalizedGifFiles.contains(path)) {
      _future = null;
      return;
    }

    _future = _normalize(image.file);
  }

  Future<void> _normalize(File file) async {
    try {
      await normalizeGifFileIfNeeded(file, ImageType.gif.mimeType);
      await FileImage(file).evict();
    } finally {
      _normalizedGifFiles.add(file.absolute.path);
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
