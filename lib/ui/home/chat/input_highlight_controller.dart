part of 'input_container.dart';

class MentionTextMatcher extends TextMatcher implements EquatableMixin {
  MentionTextMatcher(this.mentionCache, this.highlightTextStyle)
    : super.regExp(
        regExp: mentionNumberRegExp,
        matchBuilder: (span, displayString, linkString) {
          if (displayString != linkString) return TextSpan(text: linkString);

          final identityNumber = linkString.substring(1);
          final user = mentionCache.identityNumberCache(identityNumber);
          final valid = user != null;

          return TextSpan(
            text: displayString,
            style: valid
                ? (span.style ?? const TextStyle()).merge(
                    highlightTextStyle,
                  )
                : span.style,
          );
        },
      );

  final MentionCache mentionCache;
  final TextStyle highlightTextStyle;

  @override
  List<Object?> get props => [mentionCache, highlightTextStyle];

  @override
  bool? get stringify => true;
}

class _HighlightTextEditingController extends TextEditingController {
  _HighlightTextEditingController({
    required this.highlightTextStyle,
    required this.mentionCache,
    String? initialText,
  }) : super(text: initialText) {
    mentionsStreamController.stream
        .distinct()
        .asyncBufferMap(
          (event) => mentionCache.checkMentionCache(event.toSet()),
        )
        .distinct(mapEquals)
        .listen((event) => notifyListeners());
  }

  final TextStyle highlightTextStyle;
  final MentionCache mentionCache;
  final mentionsStreamController = StreamController<String>();

  @override
  Future<void> dispose() async {
    await mentionsStreamController.close();
    return super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    mentionsStreamController.add(text);
    if (!value.isComposingRangeValid || !withComposing) {
      return _buildTextSpan(text, style);
    }

    return TextSpan(
      style: style,
      children: <TextSpan>[
        _buildTextSpan(value.composing.textBefore(value.text), style),
        _buildTextSpan(
          value.composing.textInside(value.text),
          style?.merge(const TextStyle(decoration: TextDecoration.underline)),
        ),
        _buildTextSpan(value.composing.textAfter(value.text), style),
      ],
    );
  }

  TextSpan _buildTextSpan(String text, TextStyle? style) => TextSpan(
    style: style,
    children: TextMatcher.applyTextMatchers(
      [TextSpan(text: text, style: style)],
      [
        MentionTextMatcher(mentionCache, highlightTextStyle),
        EmojiTextMatcher(),
      ],
    ).toList(),
  );
}
