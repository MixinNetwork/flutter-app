import 'dart:math';
import 'dart:ui' as ui show BoxHeightStyle;

import 'package:emojis/emoji.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../db/dao/user_dao.dart';
import '../ui/provider/conversation_provider.dart';
import '../utils/emoji.dart';
import '../utils/extension/extension.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/uri_utils.dart';
import 'user/user_dialog.dart';

class HighlightText extends HookConsumerWidget {
  const HighlightText(
    this.text, {
    super.key,
    this.style,
    this.highlightTextSpans = const [],
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = useMemoized(
      () => buildHighlightTextSpan(text, highlightTextSpans, style),
      [text, highlightTextSpans, style],
    );
    return Text.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

List<InlineSpan> _handleEmojiSpans(
  String text, {
  double? fontSize,
  GestureRecognizer? recognizer,
  MouseCursor? mouseCursor,
}) {
  final spans = <InlineSpan>[];
  text.splitEmoji(
    onEmoji: (emoji) {
      spans.add(TextSpan(
        text: emoji,
        style: TextStyle(
          fontFamily: kEmojiFontFamily,
          fontSize: fontSize,
        ),
        recognizer: recognizer,
        mouseCursor: mouseCursor,
      ));
    },
    onText: (text) {
      spans.add(TextSpan(
        text: text,
        recognizer: recognizer,
        mouseCursor: mouseCursor,
      ));
    },
  );
  return spans;
}

typedef InlineMatchBuilder = InlineSpan Function(
  TextSpan originalSpan,
  String displayString,
  String linkString,
);

class TextMatcher {
  TextMatcher.regExp({
    required this.regExp,
    required this.matchBuilder,
  }) : textRangesFromText = null;

  TextMatcher.textRangesFromText({
    required this.textRangesFromText,
    required this.matchBuilder,
  }) : regExp = null;

  final InlineMatchBuilder matchBuilder;

  final RegExp? regExp;
  final Iterable<TextRange> Function(String text)? textRangesFromText;

  static Iterable<InlineSpan> matchSpans(
      Iterable<InlineSpan> spans, Iterable<TextMatcher> textMatchers) {
    final linkedSpans = _MatchedSpans(
      spans: spans,
      textMatchers: textMatchers,
    );
    return linkedSpans.linkedSpans;
  }

  static Iterable<InlineSpan> applyTextMatchers(
          Iterable<InlineSpan> spans, Iterable<TextMatcher> textMatchers) =>
      textMatchers.fold(
        spans,
        (previousValue, element) => matchSpans(previousValue, [element]),
      );

  static Iterable<TextRange> _textRangesFromText(String text, RegExp regExp) {
    final matches = regExp.allMatches(text);
    return matches.map((RegExpMatch match) => TextRange(
          start: match.start,
          end: match.end,
        ));
  }

  Iterable<_TextMatch> _link(String text) {
    final Iterable<TextRange> textRanges;
    // textRangesFromText(text) ?? _textRangesFromText(text, regExp);
    if (textRangesFromText != null) {
      textRanges = textRangesFromText!(text);
    } else if (regExp != null) {
      textRanges = _textRangesFromText(text, regExp!);
    } else {
      throw ArgumentError('regExp or textRangesFromText must not be null');
    }
    return textRanges.map((TextRange textRange) => _TextMatch(
          textRange: textRange,
          linkBuilder: matchBuilder,
          linkString: text.substring(textRange.start, textRange.end),
        ));
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TextLinker')}($regExp)';
}

class _TextMatch {
  _TextMatch({
    required this.textRange,
    required this.linkBuilder,
    required this.linkString,
  }) : assert(textRange.end - textRange.start == linkString.length);

  final InlineMatchBuilder linkBuilder;
  final TextRange textRange;

  final String linkString;

  static List<_TextMatch> fromTextLinkers(
          Iterable<TextMatcher> textMatchers, String text) =>
      textMatchers.fold<List<_TextMatch>>(
          <_TextMatch>[],
          (List<_TextMatch> previousValue, TextMatcher value) =>
              previousValue..addAll(value._link(text)));

  @override
  String toString() =>
      '${objectRuntimeType(this, '_TextLinkerMatch')}($textRange, $linkBuilder, $linkString)';
}

class _TextCache {
  factory _TextCache({
    required InlineSpan span,
  }) {
    if (span is! TextSpan) {
      return _TextCache._(
        text: '',
        lengths: <InlineSpan, int>{span: 0},
      );
    }

    var childrenTextCache = _TextCache._empty();
    for (final child in span.children ?? <InlineSpan>[]) {
      final childTextCache = _TextCache(
        span: child,
      );
      childrenTextCache = childrenTextCache._merge(childTextCache);
    }

    final text = (span.text ?? '') + childrenTextCache.text;
    return _TextCache._(
      text: text,
      lengths: <InlineSpan, int>{
        span: text.length,
        ...childrenTextCache._lengths,
      },
    );
  }

  factory _TextCache.fromMany({
    required Iterable<InlineSpan> spans,
  }) {
    var textCache = _TextCache._empty();
    for (final span in spans) {
      final spanTextCache = _TextCache(
        span: span,
      );
      textCache = textCache._merge(spanTextCache);
    }
    return textCache;
  }

  _TextCache._empty()
      : text = '',
        _lengths = <InlineSpan, int>{};

  const _TextCache._({
    required this.text,
    required Map<InlineSpan, int> lengths,
  }) : _lengths = lengths;

  final String text;

  final Map<InlineSpan, int> _lengths;

  _TextCache _merge(_TextCache other) => _TextCache._(
        text: text + other.text,
        lengths: Map<InlineSpan, int>.from(_lengths)..addAll(other._lengths),
      );

  int? getLength(InlineSpan span) => _lengths[span];

  @override
  String toString() =>
      '${objectRuntimeType(this, '_TextCache')}($text, $_lengths)';
}

typedef _MatchSpanRecursion = (
  InlineSpan linkedSpan,
  Iterable<_TextMatch> unusedTextLinkerMatches,
);

typedef _MatchSpansRecursion = (
  Iterable<InlineSpan> linkedSpans,
  Iterable<_TextMatch> unusedTextLinkerMatches,
);

class _MatchedSpans {
  factory _MatchedSpans({
    required Iterable<InlineSpan> spans,
    required Iterable<TextMatcher> textMatchers,
  }) {
    final textCache = _TextCache.fromMany(spans: spans);

    final Iterable<_TextMatch> textMatcherMatches = _cleanTextLinkerMatches(
      _TextMatch.fromTextLinkers(textMatchers, textCache.text),
    );

    final (Iterable<InlineSpan> linkedSpans, Iterable<_TextMatch> _) =
        _linkSpansRecurse(
      spans,
      textCache,
      textMatcherMatches,
    );

    return _MatchedSpans._(
      linkedSpans: linkedSpans,
    );
  }

  const _MatchedSpans._({
    required this.linkedSpans,
  });

  final Iterable<InlineSpan> linkedSpans;

  static List<_TextMatch> _cleanTextLinkerMatches(
      Iterable<_TextMatch> textMatcherMatches) {
    final nextTextLinkerMatches = textMatcherMatches.toList()
      ..sort((_TextMatch a, _TextMatch b) =>
          a.textRange.start.compareTo(b.textRange.start));

    // Validate that there are no overlapping matches.
    var lastEnd = 0;
    for (final textMatcherMatch in nextTextLinkerMatches) {
      if (textMatcherMatch.textRange.start < lastEnd) {
        throw ArgumentError(
            'Matches must not overlap. Overlapping text was "${textMatcherMatch.linkString}" located at ${textMatcherMatch.textRange.start}-${textMatcherMatch.textRange.end}.');
      }
      lastEnd = textMatcherMatch.textRange.end;
    }

    // Remove empty ranges.
    nextTextLinkerMatches.removeWhere((_TextMatch textMatcherMatch) =>
        textMatcherMatch.textRange.start == textMatcherMatch.textRange.end);

    return nextTextLinkerMatches;
  }

  static _MatchSpansRecursion _linkSpansRecurse(Iterable<InlineSpan> spans,
      _TextCache textCache, Iterable<_TextMatch> textMatcherMatches,
      [int index = 0]) {
    final output = <InlineSpan>[];
    var nextTextLinkerMatches = textMatcherMatches;
    var nextIndex = index;
    for (final span in spans) {
      final (
        InlineSpan childSpan,
        Iterable<_TextMatch> childTextLinkerMatches
      ) = _linkSpanRecurse(
        span,
        textCache,
        nextTextLinkerMatches,
        nextIndex,
      );
      output.add(childSpan);
      nextTextLinkerMatches = childTextLinkerMatches;
      nextIndex += textCache.getLength(span)!;
    }

    return (output, nextTextLinkerMatches);
  }

  static _MatchSpanRecursion _linkSpanRecurse(InlineSpan span,
      _TextCache textCache, Iterable<_TextMatch> textMatcherMatches,
      [int index = 0]) {
    if (span is! TextSpan) {
      return (span, textMatcherMatches);
    }

    final nextChildren = <InlineSpan>[];
    var nextTextLinkerMatches = <_TextMatch>[...textMatcherMatches];
    var lastLinkEnd = index;
    if (span.text?.isNotEmpty ?? false) {
      final textEnd = index + span.text!.length;
      for (final textMatcherMatch in textMatcherMatches) {
        if (textMatcherMatch.textRange.start >= textEnd) {
          // Because ranges is ordered, there are no more relevant ranges for this
          // text.
          break;
        }
        if (textMatcherMatch.textRange.end <= index) {
          // This range ends before this span and is therefore irrelevant to it.
          // It should have been removed from ranges.
          assert(false, 'Invalid ranges.');
          nextTextLinkerMatches.removeAt(0);
          continue;
        }
        if (textMatcherMatch.textRange.start > index) {
          // Add the unlinked text before the range.
          nextChildren.add(TextSpan(
            text: span.text!.substring(
              lastLinkEnd - index,
              textMatcherMatch.textRange.start - index,
            ),
            recognizer: span.recognizer,
            mouseCursor: span.mouseCursor,
            onEnter: span.onEnter,
            onExit: span.onExit,
            semanticsLabel: span.semanticsLabel,
            locale: span.locale,
            spellOut: span.spellOut,
          ));
        }
        // Add the link itself.
        final int linkStart = max(textMatcherMatch.textRange.start, index);
        lastLinkEnd = min(textMatcherMatch.textRange.end, textEnd);
        final nextChild = textMatcherMatch.linkBuilder(
          span,
          span.text!.substring(linkStart - index, lastLinkEnd - index),
          textMatcherMatch.linkString,
        );
        nextChildren.add(nextChild);
        if (textMatcherMatch.textRange.end > textEnd) {
          // If we only partially used this range, keep it in nextRanges. Since
          // overlapping ranges have been removed, this must be the last relevant
          // range for this span.
          break;
        }
        nextTextLinkerMatches.removeAt(0);
      }

      // Add any extra text after any ranges.
      final remainingText = span.text!.substring(lastLinkEnd - index);
      if (remainingText.isNotEmpty) {
        nextChildren.add(TextSpan(
          text: remainingText,
          recognizer: span.recognizer,
          mouseCursor: span.mouseCursor,
          onEnter: span.onEnter,
          onExit: span.onExit,
          semanticsLabel: span.semanticsLabel,
          locale: span.locale,
          spellOut: span.spellOut,
        ));
      }
    }

    // Recurse on the children.
    if (span.children?.isNotEmpty ?? false) {
      final (
        Iterable<InlineSpan> childrenSpans,
        Iterable<_TextMatch> childrenTextLinkerMatches,
      ) = _linkSpansRecurse(
        span.children!,
        textCache,
        nextTextLinkerMatches,
        index + (span.text?.length ?? 0),
      );
      nextTextLinkerMatches = childrenTextLinkerMatches.toList();
      nextChildren.addAll(childrenSpans);
    }

    return (
      TextSpan(
        style: span.style,
        children: nextChildren,
        recognizer: span.recognizer,
        mouseCursor: span.mouseCursor,
        onEnter: span.onEnter,
        onExit: span.onExit,
        semanticsLabel: span.semanticsLabel,
        locale: span.locale,
        spellOut: span.spellOut,
      ),
      nextTextLinkerMatches,
    );
  }
}

List<InlineSpan> buildHighlightTextSpan(
    String text, List<HighlightTextSpan> highlightTextSpans,
    [TextStyle? style]) {
  final map = Map<String, HighlightTextSpan>.fromIterable(
    highlightTextSpans.where((element) => element.text.isNotEmpty),
    key: (item) => (item as HighlightTextSpan).text.toLowerCase(),
  );
  final pattern = "(${map.keys.map(RegExp.escape).join('|')})";

  if (pattern == '()') {
    return [TextSpan(children: _handleEmojiSpans(text), style: style)];
  }

  final children = <InlineSpan>[];
  text.splitMapJoin(
    RegExp(pattern, caseSensitive: false),
    onMatch: (Match match) {
      final text = match[0];
      final highlightTextSpan = map[text?.toLowerCase()];
      final mouseCursor =
          highlightTextSpan?.onTap != null ? SystemMouseCursors.click : null;
      if (text != null) {
        final recognizer = highlightTextSpan?.onTap == null
            ? null
            : (TapGestureRecognizer()..onTap = highlightTextSpan?.onTap);
        children.add(
          TextSpan(
            mouseCursor: mouseCursor,
            children: _handleEmojiSpans(
              text,
              recognizer: recognizer,
              mouseCursor: mouseCursor,
            ),
            style: style?.merge(highlightTextSpan?.style) ??
                highlightTextSpan?.style,
            recognizer: recognizer,
          ),
        );
      }
      return '';
    },
    onNonMatch: (text) {
      children.add(TextSpan(children: _handleEmojiSpans(text), style: style));
      return '';
    },
  );

  return children;
}

class UrlTextLinker extends TextMatcher {
  UrlTextLinker(BuildContext context)
      : super.regExp(
          regExp: uriRegExp,
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) =>
              TextSpan(
            text: displayString,
            style: TextStyle(color: context.theme.accent),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () => openUri(context, linkString,
                  app: context.providerContainer.read(
                      conversationProvider.select((value) => value?.app))),
          ),
        );
}

class MailTextLinker extends TextMatcher {
  MailTextLinker(BuildContext context)
      : super.regExp(
          regExp: mailRegExp,
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) =>
              TextSpan(
            text: displayString,
            style: TextStyle(color: context.theme.accent),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlString(linkString),
          ),
        );
}

class EmojiTextLinker extends TextMatcher {
  EmojiTextLinker()
      : super.regExp(
          regExp: emojiRegex,
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) =>
              TextSpan(
            text: displayString,
            style: TextStyle(fontFamily: kEmojiFontFamily),
            recognizer: span.recognizer,
            mouseCursor: span.mouseCursor,
            onEnter: span.onEnter,
            onExit: span.onExit,
            semanticsLabel: span.semanticsLabel,
            locale: span.locale,
            spellOut: span.spellOut,
          ),
        );
}

class KeyWordTextLinker extends TextMatcher {
  KeyWordTextLinker(BuildContext context, String keyword,
      [bool caseSensitive = true])
      : super.regExp(
          regExp: RegExp(RegExp.escape(keyword), caseSensitive: caseSensitive),
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) =>
              TextSpan(
            text: displayString,
            style: TextStyle(
              backgroundColor: context.theme.highlight,
              color: context.theme.text,
            ),
            recognizer: span.recognizer,
            mouseCursor: span.mouseCursor,
            onEnter: span.onEnter,
            onExit: span.onExit,
            semanticsLabel: span.semanticsLabel,
            locale: span.locale,
            spellOut: span.spellOut,
          ),
        );
}

class BotNumberTextLinker extends TextMatcher {
  BotNumberTextLinker(BuildContext context)
      : super.regExp(
          regExp: botNumberRegExp,
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) =>
              TextSpan(
            text: displayString,
            style: TextStyle(color: context.theme.accent),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showUserDialog(context, null, linkString),
          ),
        );
}

class MentionTextLinker extends TextMatcher {
  MentionTextLinker(BuildContext context, Map<String, MentionUser> map)
      : super.regExp(
          regExp: RegExp('(${map.keys.map((e) => '@$e').join('|')})'),
          matchBuilder: (
            span,
            displayString,
            linkString,
          ) {
            final mentionUser = map[linkString.substring(1)];
            if (displayString != linkString || mentionUser == null) {
              return TextSpan(text: linkString);
            }

            return TextSpan(
              text: '@${mentionUser.fullName ?? mentionUser.identityNumber}',
              style: TextStyle(color: context.theme.accent),
              mouseCursor: SystemMouseCursors.click,
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    showUserDialog(context, null, mentionUser.identityNumber),
            );
          },
        );
}

class HighlightSelectableText extends HookConsumerWidget {
  const HighlightSelectableText(
    this.text, {
    super.key,
    this.style,
    this.highlightTextSpans = const [],
    this.maxLines,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final List<HighlightTextSpan> highlightTextSpans;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = useMemoized(
      () => buildHighlightTextSpan(text, highlightTextSpans, style),
      [text, highlightTextSpans, style],
    );

    return SelectableText.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: maxLines,
      contextMenuBuilder: (context, editState) => const SizedBox.shrink(),
      selectionHeightStyle: ui.BoxHeightStyle.includeLineSpacingMiddle,
      textAlign: textAlign,
    );
  }
}

class HighlightTextSpan extends Equatable {
  const HighlightTextSpan(
    this.text, {
    this.onTap,
    this.style,
  });

  final String text;
  final VoidCallback? onTap;
  final TextStyle? style;

  @override
  List<Object?> get props => [
        text,
        style,
        onTap,
      ];
}

class HighlightStarLinkText extends HookConsumerWidget {
  const HighlightStarLinkText(
    this.text, {
    super.key,
    required this.links,
    this.style,
    this.highlightStyle,
    this.onLinkClick,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final List<String> links;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final void Function(String link)? onLinkClick;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = useMemoized(
      () {
        // replace ** around text with highlight text span
        var start = text.indexOf('**');
        var end = 0;
        final spans = <TextSpan>[];

        if (start == -1) {
          spans.add(TextSpan(text: text, style: style));
          return spans;
        }
        var count = 0;
        while (start != -1) {
          end = text.indexOf('**', start + 2);
          if (end == -1) {
            assert(false, 'text must be surrounded by **. $text');
            spans.add(TextSpan(text: text.substring(start), style: style));
            break;
          }

          // add text before **
          if (start > 0) {
            spans.add(TextSpan(text: text.substring(0, start), style: style));
          }

          final link = links[count];
          spans.add(
            TextSpan(
              text: text.substring(start + 2, end),
              style: style?.merge(highlightStyle),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  onLinkClick?.call(link);
                },
            ),
          );
          start = text.indexOf('**', end + 2);
          count++;
        }
        // add text after end.
        if (end + 2 < text.length) {
          spans.add(TextSpan(text: text.substring(end + 2), style: style));
        }
        return spans;
      },
      [text, highlightStyle, links],
    );
    return Text.rich(
      TextSpan(
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}
