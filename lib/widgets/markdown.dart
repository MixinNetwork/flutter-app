import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_markdown_widget/mixin_markdown_widget.dart';

import '../ui/provider/setting_provider.dart';
import '../utils/extension/extension.dart';
import '../utils/uri_utils.dart';
import 'mixin_image.dart';

class MarkdownColumn extends ConsumerWidget {
  const MarkdownColumn({
    required this.data,
    super.key,
    this.selectable = false,
  });

  final String data;
  final bool selectable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatFontSizeDelta = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return ClipRect(
      child: MarkdownWidget(
        data: data,
        useColumn: true,
        selectable: selectable,
        contextMenuBuilder: (_, _, _, _) => const SizedBox.shrink(),
        padding: EdgeInsets.zero,
        theme: _createMarkdownTheme(context, chatFontSizeDelta),
        imageBuilder: _buildMarkdownImage,
        onTapLink: (destination, title, label) {
          if (destination.isEmpty) return;
          openUri(context, destination);
        },
      ),
    );
  }
}

class Markdown extends ConsumerWidget {
  const Markdown({
    required this.data,
    super.key,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  final String data;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatFontSizeDelta = ref.watch(
      settingProvider.select((value) => value.chatFontSizeDelta),
    );

    return MarkdownWidget(
      data: data,
      padding: padding,
      physics: physics,
      theme: _createMarkdownTheme(context, chatFontSizeDelta),
      imageBuilder: _buildMarkdownImage,
      onTapLink: (destination, title, label) {
        if (destination.isEmpty) return;
        openUri(context, destination);
      },
    );
  }
}

Widget _buildMarkdownImage(
  BuildContext context,
  ImageBlock block,
  MarkdownThemeData theme,
) {
  final uri = Uri.tryParse(block.url);
  final width = _tryParseImageDimension(uri, 'w', 'width');
  final height = _tryParseImageDimension(uri, 'h', 'height');

  Widget errorBuilder(BuildContext context, Object error, StackTrace? stack) {
    final iconColor = theme.bodyStyle.color?.withValues(alpha: 0.72);
    if (width != null && height != null) {
      return Container(
        width: width,
        height: height,
        color: theme.imagePlaceholderBackgroundColor,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: theme.dividerColor),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.imagePlaceholderBackgroundColor,
        borderRadius: theme.imageBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              block.alt?.isNotEmpty == true ? block.alt! : 'Image',
              style: theme.bodyStyle.copyWith(color: iconColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  final image = _buildMixinImageForUrl(
    block.url,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );

  return ClipRRect(
    borderRadius: theme.imageBorderRadius,
    child: image,
  );
}

double? _tryParseImageDimension(Uri? uri, String shortKey, String fullKey) {
  if (uri == null) return null;
  final value = uri.queryParameters[shortKey] ?? uri.queryParameters[fullKey];
  return value == null ? null : double.tryParse(value);
}

Widget _buildMixinImageForUrl(
  String url, {
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return MixinImage.network(
      url,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  if (uri != null && uri.scheme == 'file') {
    return MixinImage.file(
      File.fromUri(uri),
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  final file = File(url);
  if (file.isAbsolute) {
    return MixinImage.file(
      file,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
    );
  }

  return MixinImage.asset(
    url,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}

MarkdownThemeData _createMarkdownTheme(
  BuildContext context,
  double chatFontSizeDelta,
) {
  final base = MarkdownThemeData.fallback(context);
  final textColor = context.theme.text;
  final accentColor = context.theme.accent;
  final codeBlockBackgroundColor = context.theme.chatBackground;

  TextStyle applyTextColor(TextStyle style) => style.copyWith(color: textColor);
  TextStyle applyFontSizeDelta(TextStyle style) {
    final fontSize = style.fontSize;
    if (fontSize == null) return style;
    return style.copyWith(fontSize: fontSize + chatFontSizeDelta);
  }

  TextStyle applyTextStyle(TextStyle style) =>
      applyTextColor(applyFontSizeDelta(style));

  return base.copyWith(
    bodyStyle: applyTextStyle(base.bodyStyle),
    quoteStyle: applyFontSizeDelta(
      base.quoteStyle.copyWith(
        color: textColor.withValues(alpha: 0.82),
      ),
    ),
    linkStyle: base.linkStyle.copyWith(
      color: accentColor,
      decorationColor: accentColor,
      fontSize:
          (base.linkStyle.fontSize ?? base.bodyStyle.fontSize ?? 16) +
          chatFontSizeDelta,
    ),
    inlineCodeStyle: applyTextStyle(base.inlineCodeStyle),
    codeBlockStyle: applyTextStyle(base.codeBlockStyle),
    codeBlockBackgroundColor: codeBlockBackgroundColor,
    inlineCodeBackgroundColor: codeBlockBackgroundColor,
    quoteBackgroundColor: codeBlockBackgroundColor,
    tableHeaderStyle: applyTextStyle(base.tableHeaderStyle),
    heading1Style: applyTextStyle(
      applyFontSizeDelta(
        base.heading1Style.copyWith(
          fontSize: 32,
          height: 40 / 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    heading2Style: applyTextStyle(base.heading2Style),
    heading3Style: applyTextStyle(base.heading3Style),
    heading4Style: applyTextStyle(base.heading4Style),
    heading5Style: applyTextStyle(base.heading5Style),
    heading6Style: applyTextStyle(base.heading6Style),
    quoteBorderColor: accentColor.withValues(alpha: 0.4),
    selectionColor: accentColor.withValues(alpha: 0.24),
    showHeading1Divider: false,
  );
}
