import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../utils/extension/extension.dart';
import '../utils/uri_utils.dart';
import 'cache_image.dart';

// StyleConfig buildMarkdownStyleConfig(BuildContext context, bool darkMode) =>
//     StyleConfig(
//       markdownTheme:
//           darkMode ? MarkdownTheme.darkTheme : MarkdownTheme.lightTheme,
//       imgBuilder: (url, attributes) {
//         double? width;
//         double? height;
//         if (attributes['width'] != null) {
//           width = double.parse(attributes['width']!);
//         }
//         if (attributes['height'] != null) {
//           height = double.parse(attributes['height']!);
//         }
//         final imageUrl = url;
//
//         return ConstrainedBox(
//           constraints: const BoxConstraints(maxWidth: 400),
//           child: CacheImage(
//             imageUrl,
//             width: width,
//             height: height,
//           ),
//         );
//       },
//       pConfig: PConfig(
//         onLinkTap: (href) {
//           if (href?.isEmpty ?? true) return;
//           openUri(context, href!);
//         },
//       ),
//       olConfig: OlConfig(selectable: false),
//       ulConfig: UlConfig(selectable: false),
//     );

class Markdown extends StatelessWidget {
  const Markdown({
    super.key,
    required this.data,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  final String data;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    debugPrint('context.brightness: ${context.brightness}');
    return DefaultTextStyle.merge(
      style: TextStyle(color: context.theme.text),
      child: MarkdownWidget(
        data: data,
        padding: padding,
        physics: physics,
        config: _createMarkdownConfig(
          context: context,
          darkMode: context.brightness == Brightness.dark,
        ),
      ),
    );
  }
}

MarkdownConfig _createMarkdownConfig({
  required BuildContext context,
  required bool darkMode,
}) =>
    MarkdownConfig(configs: [
      if (darkMode) ...[
        HrConfig.darkConfig,
        H2Config.darkConfig,
        H3Config.darkConfig,
        H4Config.darkConfig,
        H5Config.darkConfig,
        H6Config.darkConfig,
        PreConfig.darkConfig,
        PConfig.darkConfig,
        CodeConfig.darkConfig,
      ],
      _MixinH1Config(darkMode),
      ImgConfig(builder: (url, attributes) {
        double? width;
        double? height;
        if (attributes['width'] != null) {
          width = double.parse(attributes['width']!);
        }
        if (attributes['height'] != null) {
          height = double.parse(attributes['height']!);
        }
        final imageUrl = url;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: CacheImage(
            imageUrl,
            width: width,
            height: height,
          ),
        );
      }),
      LinkConfig(onTap: (href) {
        if (href.isEmpty) return;
        openUri(context, href);
      }),
      ListConfig(
        marker: (bool isOrdered, int depth, int index) => getDefaultMarker(
          isOrdered,
          depth,
          context.theme.text,
          index,
          8,
          MarkdownConfig(),
        ),
      )
    ]);

class _MixinH1Config extends HeadingConfig {
  _MixinH1Config(this.dark);

  final bool dark;

  @override
  HeadingDivider? get divider => null;

  @override
  TextStyle get style => TextStyle(
        fontSize: 32,
        height: 40 / 32,
        color: dark ? Colors.white : null,
        fontWeight: FontWeight.bold,
      );

  @override
  String get tag => MarkdownTag.h1.name;
}
