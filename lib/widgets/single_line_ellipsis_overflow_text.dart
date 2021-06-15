import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

class SingleLineEllipsisOverflowText extends StatelessWidget {
  const SingleLineEllipsisOverflowText(
    this.data, {
    Key? key,
    this.style,
  }) : super(key: key);

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _SingleLineEllipsisOverflowPinter(data, style: style),
      );
}

class _SingleLineEllipsisOverflowPinter extends CustomPainter {
  _SingleLineEllipsisOverflowPinter(
    this.data, {
    this.style,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final String data;
  final TextStyle? style;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = const LineSplitter().convert(data);
    if (lines.isEmpty) return;
    var ellipsis = lines.length > 1;

    final width = size.width;
    final ellipsisWidth = layoutEllipsisWidth(style, width);

    final expectMaxChatCount = width / (ellipsisWidth / 3).ceil();
    var text = lines.first;

    ellipsis = ellipsis || expectMaxChatCount > text.length;

    final expectMaxText =
        text.substring(0, min(expectMaxChatCount.ceil(), text.length));
    text = expectMaxText;

    double? lastTextWidth;
    TextPainter? lastTextPainter;
    while (true) {
      if (text.isEmpty) {
        lastTextPainter =
            generateTextPainter(expectMaxText, style, width, ellipsis);
        break;
      }

      lastTextPainter = generateTextPainter(text, style, width, ellipsis);
      final currentTextWidth = lastTextPainter.computeLineMetrics().first.width;
      if (lastTextWidth != null && currentTextWidth > lastTextWidth) break;

      lastTextWidth = currentTextWidth;
      text = text.substring(0, text.length - 1);
      ellipsis = true;
    }

    lastTextPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  double layoutEllipsisWidth(TextStyle? style, double width) {
    final textSpan = TextSpan(
      text: '...',
      style: style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(
        minWidth: 0,
        maxWidth: width,
      );

    return textPainter.width;
  }

  TextPainter generateTextPainter(
      String text, TextStyle? style, double width, bool ellipsis) {
    final _text = '$text${ellipsis ? '\u200B...' : ''}';
    final textSpan = TextSpan(
      text: _text,
      style: style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(
        minWidth: 0,
        maxWidth: width,
      );

    return textPainter;
  }
}
