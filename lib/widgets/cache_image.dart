import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class CacheImage extends StatelessWidget {
  const CacheImage(
    this.src, {
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  final String src;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
      );
}
