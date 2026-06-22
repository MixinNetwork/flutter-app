import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../utils/image.dart';
import '../utils/proxy.dart';

final _checkedImageFiles = <String>{};

bool shouldUseMediaImagePipeline(
  String url,
  ProxyConfig? proxyConfig, {
  bool normalizeGif = false,
}) => normalizeGif || proxyConfig != null || isLikelyGifUrl(url);

@visibleForTesting
bool isLikelyGifUrl(String url) {
  final path = Uri.tryParse(url)?.path ?? url.split('?').first;
  return path.toLowerCase().endsWith('.gif');
}

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
    final fileName = image.file.uri.pathSegments.last.toLowerCase();
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
