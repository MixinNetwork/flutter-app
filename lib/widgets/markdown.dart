import 'package:flutter/widgets.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../utils/uri_utils.dart';
import 'cache_image.dart';

StyleConfig buildMarkdownStyleConfig(BuildContext context, bool darkMode) =>
    StyleConfig(
      markdownTheme:
          darkMode ? MarkdownTheme.darkTheme : MarkdownTheme.lightTheme,
      imgBuilder: (url, attributes) {
        double? width;
        double? height;
        if (attributes['width'] != null) {
          width = double.parse(attributes['width']!);
        }
        if (attributes['height'] != null) {
          height = double.parse(attributes['height']!);
        }
        final imageUrl = url;

        return CacheImage(
          imageUrl,
          width: width,
          height: height,
        );
      },
      pConfig: PConfig(
        onLinkTap: (href) {
          if (href?.isEmpty ?? true) return;
          openUri(context, href!);
        },
        selectable: false,
      ),
      olConfig: OlConfig(selectable: false),
      ulConfig: UlConfig(selectable: false),
    );

class Markdown extends StatelessWidget {
  const Markdown({
    super.key,
    required this.data,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.darkMode = false,
  });

  final String data;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool darkMode;

  @override
  Widget build(BuildContext context) => MarkdownWidget(
        data: data,
        padding: padding,
        physics: physics,
        styleConfig: buildMarkdownStyleConfig(context, darkMode),
      );
}
