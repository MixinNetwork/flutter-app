import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class CacheImage extends StatelessWidget {
  const CacheImage(
    this.src, {
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    Key? key,
  }) : super(key: key);

  final String src;
  final double? width;
  final double? height;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: placeholder,
        errorWidget: errorWidget,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 400),
      );
}
