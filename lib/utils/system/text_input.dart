import 'package:flutter/widgets.dart';

import '../emoji.dart';

/// A [TextEditingController] that supports emojis.
class EmojiTextEditingController extends TextEditingController {
  EmojiTextEditingController({super.text});

  TextSpan _buildSpan({required String text, TextStyle? style}) {
    final children = <TextSpan>[];
    text.splitEmoji(
      onEmoji: (text) {
        children.add(
          TextSpan(
            text: text,
            style:
                style?.copyWith(fontFamily: kEmojiFontFamily) ??
                TextStyle(fontFamily: kEmojiFontFamily),
          ),
        );
      },
      onText: (text) {
        children.add(TextSpan(text: text, style: style));
      },
    );
    return TextSpan(children: children, style: style);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    assert(
      !value.composing.isValid || !withComposing || value.isComposingRangeValid,
    );
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final composingRegionOutOfRange =
        !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      return _buildSpan(text: value.text, style: style);
    }

    final composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
        const TextStyle(decoration: TextDecoration.underline);
    return TextSpan(
      style: style,
      children: <TextSpan>[
        _buildSpan(text: value.composing.textBefore(value.text)),
        _buildSpan(
          style: composingStyle,
          text: value.composing.textInside(value.text),
        ),
        _buildSpan(text: value.composing.textAfter(value.text)),
      ],
    );
  }
}
