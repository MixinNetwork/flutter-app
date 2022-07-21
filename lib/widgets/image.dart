import 'dart:convert';
import 'dart:ui' as ui;

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class _ImageByBase64 extends HookWidget {
  const _ImageByBase64(
    this.base64String, {
    this.fit = BoxFit.cover,
  });

  final String base64String;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final bytes = useMemoized(() => base64Decode(base64String), [base64String]);
    return Image.memory(
      bytes,
      fit: fit,
    );
  }
}

const _kDefaultBlurHashSize = 20;

class _ImageByBlurHash extends HookWidget {
  const _ImageByBlurHash({
    required this.blurHash,
    this.width = _kDefaultBlurHashSize,
    this.height = _kDefaultBlurHashSize,
    // ignore: unused_element
    this.fit = BoxFit.cover,
  })  : assert(width > 0),
        assert(height > 0);

  final BlurHash blurHash;
  final int width;
  final int height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final image = useState<ui.Image?>(null);
    useEffect(() {
      ui.decodeImageFromPixels(
        blurHash.toImage(width, height).getBytes(),
        width,
        height,
        ui.PixelFormat.rgba8888,
        (result) {
          image.value = result;
        },
      );
    }, [blurHash, width, height]);
    return RawImage(
      image: image.value,
      width: width.toDouble(),
      height: height.toDouble(),
      fit: fit,
    );
  }
}

///
/// when [imageData] is blur hash. render it with [_ImageByBlurHash]
/// when [imageData] is Base64, render it with [_ImageByBase64]
///
class ImageByBlurHashOrBase64 extends HookWidget {
  const ImageByBlurHashOrBase64({
    super.key,
    required this.imageData,
    this.fit = BoxFit.cover,
  });

  /// could be image
  final String imageData;

  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final blurHash = useMemoized(() {
      try {
        return BlurHash.decode(imageData);
      } catch (_) {
        return null;
      }
    }, [imageData]);

    return blurHash != null
        ? _ImageByBlurHash(blurHash: blurHash)
        : _ImageByBase64(imageData, fit: fit);
  }
}
