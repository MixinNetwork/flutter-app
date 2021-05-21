import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    Key? key,
    this.style,
    this.highlightTextSpans = const [],
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: _buildSpan(text, highlightTextSpans, style),
        ),
        maxLines: maxLines,
        overflow: overflow,
        textWidthBasis: TextWidthBasis.longestLine,
      );
}

List<InlineSpan> _buildSpan(
    String text, List<HighlightTextSpan> highlightTextSpans,
    [TextStyle? style]) {
  final map = Map<String, HighlightTextSpan>.fromIterable(
    highlightTextSpans.where((element) => element.text.isNotEmpty == true),
    key: (item) => (item as HighlightTextSpan).text.toLowerCase(),
  );
  final pattern = "(${map.keys.map(RegExp.escape).join('|')})";

  if (pattern == '()') return [TextSpan(text: text, style: style)];

  final children = <InlineSpan>[];
  text.splitMapJoin(
    RegExp(pattern, caseSensitive: false),
    onMatch: (Match match) {
      final text = match[0];
      final highlightTextSpan = map[text?.toLowerCase()];
      final mouseCursor =
          highlightTextSpan?.onTap != null ? SystemMouseCursors.click : null;
      children.add(
        TextSpan(
          mouseCursor: mouseCursor,
          text: text,
          style: style?.merge(highlightTextSpan?.style) ??
              highlightTextSpan?.style,
          recognizer: TapGestureRecognizer()..onTap = highlightTextSpan?.onTap,
        ),
      );
      return '';
    },
    onNonMatch: (text) {
      children.add(TextSpan(text: text, style: style));
      return '';
    },
  );

  return children;
}

class HighlightSelectableText extends StatelessWidget {
  const HighlightSelectableText(
    this.text, {
    Key? key,
    this.style,
    this.highlightTextSpans = const [],
    this.maxLines,
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => SelectableText.rich(
        TextSpan(
          children: _buildSpan(text, highlightTextSpans, style),
        ),
        maxLines: maxLines,
        textWidthBasis: TextWidthBasis.longestLine,
        toolbarOptions: const ToolbarOptions(),
      );
}

class HighlightTextSpan {
  HighlightTextSpan(
    this.text, {
    this.onTap,
    this.style,
  });

  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;
}
