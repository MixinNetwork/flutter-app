import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    Key? key,
    this.style,
    this.highlightTextSpans = const [],
  }) : super(key: key);

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: _buildSpan(),
        ),
      );

  List<InlineSpan> _buildSpan() {
    final map = Map<String, HighlightTextSpan>.fromIterable(
      highlightTextSpans.where((element) => element.text.isNotEmpty == true),
      key: (item) => item.text.toLowerCase(),
    );
    final pattern = "(${map.keys.map(RegExp.escape).join('|')})";

    if(pattern == '()')
      return [TextSpan(text: text, style: style)];

    final children = <InlineSpan>[];
    text.splitMapJoin(
      RegExp(pattern, caseSensitive: false),
      onMatch: (Match match) {
        final text = match[0];
        final highlightTextSpan = map[text?.toLowerCase()];
        children.add(
          TextSpan(
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
