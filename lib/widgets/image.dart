import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../utils/load_balancer_utils.dart';
import '../utils/logger.dart';

class _ImageByBase64 extends HookConsumerWidget {
  const _ImageByBase64(this.base64String, {this.fit = BoxFit.cover});

  final String base64String;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = useMemoized(() {
      try {
        return base64Decode(base64String);
      } catch (error, stacktrace) {
        e('Failed to decode base64 string: $base64String', error, stacktrace);
        return null;
      }
    }, [base64String]);
    if (bytes == null) {
      return const SizedBox();
    }
    return Image.memory(bytes, fit: fit);
  }
}

const _kBlurHashSize = 20;

Uint8List _blurHashPixels(String hash) =>
    BlurHash.decode(hash).toImage(_kBlurHashSize, _kBlurHashSize).getBytes();

// Recently shown placeholders, oldest first. One holds 1.6KB of pixels.
// Evicted images are not disposed because a RawImage can still paint them.
final _blurHashImages = <String, ui.Image>{};
final _blurHashLoads = <String, Future<ui.Image>>{};

ui.Image? _cachedBlurHashImage(String hash) {
  final image = _blurHashImages.remove(hash);
  if (image != null) _blurHashImages[hash] = image;
  return image;
}

// The pixels take about 0.2ms each on the UI thread, and a page of shared
// media shows dozens of them in its first frame.
Future<ui.Image> _loadBlurHashImage(String hash) =>
    _blurHashLoads[hash] ??= () async {
      try {
        final pixels = await runLoadBalancer(_blurHashPixels, hash);
        final completer = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          pixels,
          _kBlurHashSize,
          _kBlurHashSize,
          ui.PixelFormat.rgba8888,
          completer.complete,
        );
        final image = await completer.future;
        if (_blurHashImages.length >= 500) {
          _blurHashImages.remove(_blurHashImages.keys.first);
        }
        return _blurHashImages[hash] = image;
      } finally {
        unawaited(_blurHashLoads.remove(hash));
      }
    }();

class _ImageByBlurHash extends HookWidget {
  const _ImageByBlurHash(this.hash);

  final String hash;

  @override
  Widget build(BuildContext context) {
    final cached = _cachedBlurHashImage(hash);
    final loaded = useFuture(
      useMemoized(() => cached == null ? _loadBlurHashImage(hash) : null, [
        hash,
      ]),
      preserveState: false,
    ).data;
    return RawImage(fit: BoxFit.cover, image: cached ?? loaded);
  }
}

///
/// when [imageData] is blur hash. render it with [_ImageByBlurHash]
/// when [imageData] is Base64, render it with [_ImageByBase64]
///
class ImageByBlurHashOrBase64 extends HookConsumerWidget {
  const ImageByBlurHashOrBase64({
    required this.imageData,
    super.key,
    this.fit = BoxFit.cover,
  });

  /// could be image
  final String imageData;

  final BoxFit? fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBlurHash = useMemoized(() {
      try {
        BlurHash.decode(imageData);
        return true;
      } catch (_) {
        return false;
      }
    }, [imageData]);

    return isBlurHash
        ? _ImageByBlurHash(imageData)
        : _ImageByBase64(imageData, fit: fit);
  }
}
