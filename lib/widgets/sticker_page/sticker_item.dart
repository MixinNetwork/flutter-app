import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

import '../cache_image.dart';

class StickerItem extends StatelessWidget {
  const StickerItem({
    Key? key,
    required this.assetUrl,
    required this.assetType,
    this.placeholder,
    this.width,
    this.height,
  }) : super(key: key);

  final String assetUrl;
  final String? assetType;
  final Widget? placeholder;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    late Widget child;
    if (assetType == 'json') {
      child = Lottie.network(
        assetUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    } else {
      child = CacheImage(
        assetUrl,
        height: height,
        width: width,
        placeholder: () => placeholder ?? const SizedBox(),
      );
    }

    if (width == null || height == null) {
      return AspectRatio(aspectRatio: 1, child: child);
    }

    return child;
  }
}
