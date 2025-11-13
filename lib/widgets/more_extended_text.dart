import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../utils/extension/extension.dart';
import 'high_light_text.dart';

class MoreExtendedText extends HookConsumerWidget {
  const MoreExtendedText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, constraints) =>
        _MoreExtendedText(text, style: style, constraints: constraints),
  );
}

class _MoreExtendedText extends HookConsumerWidget {
  const _MoreExtendedText(this.text, {required this.constraints, this.style});

  final String text;
  final TextStyle? style;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expand = useState(false);
    final style = useMemoized(
      () => this.style?.merge(const TextStyle(height: 1)),
    );

    final overflowTextSpan = TextSpan(
      text: '...${context.l10n.more}',
      style: style?.merge(TextStyle(color: context.theme.accent)),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          expand.value = true;
        },
    );

    final endIndex = useMemoized(() {
      if (!expand.value) {
        final maxWidth = constraints.maxWidth;
        final textSpan = TextSpan(text: text, style: style);

        final textPainter = TextPainter(
          text: overflowTextSpan,
          textDirection: TextDirection.rtl,
          maxLines: 6,
        )..layout(minWidth: constraints.minWidth, maxWidth: maxWidth);
        final overflowTextSpanSize = textPainter.size;

        textPainter
          ..text = textSpan
          ..layout(minWidth: constraints.minWidth, maxWidth: maxWidth);

        if (textPainter.didExceedMaxLines) {
          final textSize = textPainter.size;

          final pos = textPainter.getPositionForOffset(
            Offset(
              textSize.width - overflowTextSpanSize.width,
              textSize.height,
            ),
          );
          return textPainter.getOffsetBefore(pos.offset);
        }
      }

      return -1;
    }, [text, style, expand.value]);

    final textSpan = useMemoized(() {
      var resultText = text;

      if (endIndex != -1) {
        resultText = resultText.substring(0, endIndex);
      }
      return TextSpan(text: resultText, style: style);
    }, [text, style, endIndex]);

    return CustomSelectableText.rich(
      TextSpan(children: [textSpan, if (endIndex != -1) overflowTextSpan]),
      textMatchers: [UrlTextMatcher(context), EmojiTextMatcher()],
      textAlign: TextAlign.center,
    );
  }
}
