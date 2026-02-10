import 'dart:math';
import 'dart:ui' as ui;

import 'package:data_detector/data_detector.dart';
import 'package:emojis/emoji.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../db/dao/user_dao.dart';
import '../ui/provider/conversation_provider.dart';
import '../utils/emoji.dart';
import '../utils/extension/extension.dart';
import '../utils/platform.dart';
import '../utils/reg_exp_utils.dart';
import '../utils/uri_utils.dart';
import 'menu.dart';
import 'user/user_dialog.dart';

class CustomText extends HookConsumerWidget {
  const CustomText(
    String this.text, {
    super.key,
    this.style,
    this.textMatchers,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : textSpan = null;

  const CustomText.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.textMatchers,
    this.maxLines,
    this.overflow,
    this.textAlign,
  }) : text = null;

  final String? text;
  final InlineSpan? textSpan;

  final TextStyle? style;
  final Iterable<TextMatcher>? textMatchers;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spans = useMemoized(
      () => TextMatcher.applyTextMatchers([
        textSpan ?? TextSpan(text: text, style: style),
      ], textMatchers ?? [EmojiTextMatcher()]).toList(),
      [text, style, textMatchers],
    );

    final defaultTextStyle = DefaultTextStyle.of(context);
    var effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }
    if (MediaQuery.boldTextOf(context)) {
      effectiveTextStyle = effectiveTextStyle!.merge(
        const TextStyle(fontWeight: FontWeight.bold),
      );
    }
    final registrar = SelectionContainer.maybeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);

    Widget result = _CustomRichText(
      text: TextSpan(children: spans, style: effectiveTextStyle),
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      softWrap: defaultTextStyle.softWrap,
      overflow:
          overflow ?? effectiveTextStyle?.overflow ?? defaultTextStyle.overflow,
      textScaler: textScaler,
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      textWidthBasis: defaultTextStyle.textWidthBasis,
      textHeightBehavior:
          defaultTextStyle.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
      selectionRegistrar: registrar,
      selectionColor:
          DefaultSelectionStyle.of(context).selectionColor ??
          DefaultSelectionStyle.defaultColor,
    );
    if (registrar != null) {
      result = MouseRegion(
        cursor:
            DefaultSelectionStyle.of(context).mouseCursor ??
            SystemMouseCursors.text,
        child: result,
      );
    }
    return result;
  }
}

class CustomSelectableText extends HookWidget {
  const CustomSelectableText(
    String this.text, {
    this.enableInteractiveSelection = true,
    super.key,
    this.textAlign,
    this.style,
    this.textMatchers,
    this.maxLines,
  }) : textSpan = null;

  const CustomSelectableText.rich(
    TextSpan this.textSpan, {
    this.enableInteractiveSelection = true,
    super.key,
    this.textAlign,
    this.style,
    this.textMatchers,
    this.maxLines,
  }) : text = null;

  final String? text;
  final InlineSpan? textSpan;

  final TextStyle? style;
  final Iterable<TextMatcher>? textMatchers;

  final int? maxLines;
  final TextAlign? textAlign;

  final bool enableInteractiveSelection;

  @override
  Widget build(BuildContext context) {
    final spans = useMemoized(
      () => TextMatcher.applyTextMatchers([
        textSpan ?? TextSpan(text: text, style: style),
      ], textMatchers ?? [EmojiTextMatcher()]).toList(),
      [text, style, textMatchers],
    );
    return SelectableText.rich(
      TextSpan(children: spans, style: style),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      selectionHeightStyle: ui.BoxHeightStyle.max,
      contextMenuBuilder: (context, selectableState) =>
          MixinAdaptiveSelectionToolbar(editableTextState: selectableState),
    );
  }
}

typedef InlineMatchBuilder =
    InlineSpan Function(
      TextSpan originalSpan,
      String displayString,
      String linkString,
    );

class TextMatcher {
  TextMatcher.regExp({required this.regExp, required this.matchBuilder})
    : textRangesFromText = null;

  TextMatcher.textRangesFromText({
    required this.textRangesFromText,
    required this.matchBuilder,
  }) : regExp = null;

  final InlineMatchBuilder matchBuilder;

  final RegExp? regExp;
  final Iterable<TextRange> Function(String text)? textRangesFromText;

  static Iterable<InlineSpan> matchSpans(
    Iterable<InlineSpan> spans,
    Iterable<TextMatcher> textMatchers,
  ) {
    final linkedSpans = _MatchedSpans(spans: spans, textMatchers: textMatchers);
    return linkedSpans.linkedSpans;
  }

  static Iterable<InlineSpan> applyTextMatchers(
    Iterable<InlineSpan> spans,
    Iterable<TextMatcher> textMatchers,
  ) => textMatchers.fold(
    spans,
    (previousValue, element) => matchSpans(previousValue, [element]),
  );

  static Iterable<TextRange> _textRangesFromText(String text, RegExp regExp) {
    final matches = regExp.allMatches(text);
    return matches.map(
      (match) => TextRange(start: match.start, end: match.end),
    );
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
    return textRanges.map(
      (textRange) => _TextMatch(
        textRange: textRange,
        linkBuilder: matchBuilder,
        linkString: text.substring(textRange.start, textRange.end),
      ),
    );
  }

  @override
  String toString() => '${objectRuntimeType(this, 'TextMatcher')}($regExp)';
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

  static List<_TextMatch> fromTextMatchers(
    Iterable<TextMatcher> textMatchers,
    String text,
  ) => textMatchers.fold<List<_TextMatch>>(
    <_TextMatch>[],
    (previousValue, value) => previousValue..addAll(value._link(text)),
  );

  @override
  String toString() =>
      '${objectRuntimeType(this, '_TextMatcherMatch')}($textRange, $linkBuilder, $linkString)';
}

class _TextCache {
  factory _TextCache({required InlineSpan span}) {
    final lengths = <InlineSpan, int>{span: 0};
    final text = StringBuffer();

    int visitSpan(InlineSpan span) {
      if (span is! TextSpan) {
        lengths[span] = 0;
        return 0;
      }
      if (span.text != null) {
        text.write(span.text);
      }
      var length = 0;
      if (span.children != null) {
        for (final child in span.children!) {
          length += visitSpan(child);
        }
      }
      length += span.text?.length ?? 0;
      lengths[span] = length;
      return length;
    }

    lengths[span] = visitSpan(span);
    return _TextCache._(text: text.toString(), lengths: lengths);
  }

  factory _TextCache.fromMany({required Iterable<InlineSpan> spans}) {
    var textCache = _TextCache._empty();
    for (final span in spans) {
      final spanTextCache = _TextCache(span: span);
      textCache = textCache._merge(spanTextCache);
    }
    return textCache;
  }

  _TextCache._empty() : text = '', _lengths = <InlineSpan, int>{};

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
  Iterable<_TextMatch> unusedTextMatcherMatches,
);

typedef _MatchSpansRecursion = (
  Iterable<InlineSpan> linkedSpans,
  Iterable<_TextMatch> unusedTextMatcherMatches,
);

class _MatchedSpans {
  factory _MatchedSpans({
    required Iterable<InlineSpan> spans,
    required Iterable<TextMatcher> textMatchers,
  }) {
    final textCache = _TextCache.fromMany(spans: spans);

    final Iterable<_TextMatch> textMatcherMatches = _cleanTextMatcherMatches(
      _TextMatch.fromTextMatchers(textMatchers, textCache.text),
    );

    final (
      Iterable<InlineSpan> linkedSpans,
      Iterable<_TextMatch> _,
    ) = _linkSpansRecurse(
      spans,
      textCache,
      textMatcherMatches,
    );

    return _MatchedSpans._(linkedSpans: linkedSpans);
  }

  const _MatchedSpans._({required this.linkedSpans});

  final Iterable<InlineSpan> linkedSpans;

  static List<_TextMatch> _cleanTextMatcherMatches(
    Iterable<_TextMatch> textMatcherMatches,
  ) {
    final nextTextMatcherMatches = textMatcherMatches.toList()
      ..sort(
        (a, b) => a.textRange.start.compareTo(b.textRange.start),
      );

    // Validate that there are no overlapping matches.
    var lastEnd = 0;
    for (final textMatcherMatch in nextTextMatcherMatches) {
      if (textMatcherMatch.textRange.start < lastEnd) {
        throw ArgumentError(
          'Matches must not overlap. Overlapping text was "${textMatcherMatch.linkString}" located at ${textMatcherMatch.textRange.start}-${textMatcherMatch.textRange.end}.',
        );
      }
      lastEnd = textMatcherMatch.textRange.end;
    }

    // Remove empty ranges.
    nextTextMatcherMatches.removeWhere(
      (textMatcherMatch) =>
          textMatcherMatch.textRange.start == textMatcherMatch.textRange.end,
    );

    return nextTextMatcherMatches;
  }

  static _MatchSpansRecursion _linkSpansRecurse(
    Iterable<InlineSpan> spans,
    _TextCache textCache,
    Iterable<_TextMatch> textMatcherMatches, [
    int index = 0,
  ]) {
    final output = <InlineSpan>[];
    var nextTextMatcherMatches = textMatcherMatches;
    var nextIndex = index;
    for (final span in spans) {
      final (
        InlineSpan childSpan,
        Iterable<_TextMatch> childTextMatcherMatches,
      ) = _linkSpanRecurse(
        span,
        textCache,
        nextTextMatcherMatches,
        nextIndex,
      );
      output.add(childSpan);
      nextTextMatcherMatches = childTextMatcherMatches;
      nextIndex += textCache.getLength(span)!;
    }

    return (output, nextTextMatcherMatches);
  }

  static _MatchSpanRecursion _linkSpanRecurse(
    InlineSpan span,
    _TextCache textCache,
    Iterable<_TextMatch> textMatcherMatches, [
    int index = 0,
  ]) {
    if (span is! TextSpan) {
      return (span, textMatcherMatches);
    }

    final nextChildren = <InlineSpan>[];
    var nextTextMatcherMatches = <_TextMatch>[...textMatcherMatches];
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
          nextTextMatcherMatches.removeAt(0);
          continue;
        }
        if (textMatcherMatch.textRange.start > index) {
          // Add the unlinked text before the range.
          nextChildren.add(
            TextSpan(
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
            ),
          );
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
        nextTextMatcherMatches.removeAt(0);
      }

      // Add any extra text after any ranges.
      final remainingText = span.text!.substring(lastLinkEnd - index);
      if (remainingText.isNotEmpty) {
        nextChildren.add(
          TextSpan(
            text: remainingText,
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
    }

    // Recurse on the children.
    if (span.children?.isNotEmpty ?? false) {
      final (
        Iterable<InlineSpan> childrenSpans,
        Iterable<_TextMatch> childrenTextMatcherMatches,
      ) = _linkSpansRecurse(
        span.children!,
        textCache,
        nextTextMatcherMatches,
        index + (span.text?.length ?? 0),
      );
      nextTextMatcherMatches = childrenTextMatcherMatches.toList();
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
      nextTextMatcherMatches,
    );
  }
}

class UrlTextMatcher extends TextMatcher implements EquatableMixin {
  UrlTextMatcher(BuildContext context)
    : super.textRangesFromText(
        textRangesFromText: (text) {
          if (kPlatformIsDarwin) {
            final dataDetector = DataDetector(
              NSTextCheckingType.NSTextCheckingTypeLink,
            );
            return dataDetector.matchesInString(text).map((e) => e.range);
          } else {
            return TextMatcher._textRangesFromText(text, uriRegExp);
          }
        },
        matchBuilder: (span, displayString, linkString) => TextSpan(
          text: displayString,
          style: TextStyle(color: context.theme.accent),
          mouseCursor: SystemMouseCursors.click,
          recognizer: TapGestureRecognizer()
            ..onTap = () => openUri(
              context,
              linkString,
              app: context.providerContainer.read(
                conversationProvider.select((value) => value?.app),
              ),
            ),
        ),
      );

  @override
  List<Object?> get props => [];

  @override
  bool? get stringify => true;
}

class MailTextMatcher extends TextMatcher implements EquatableMixin {
  MailTextMatcher(BuildContext context)
    : super.regExp(
        regExp: mailRegExp,
        matchBuilder: (span, displayString, linkString) => TextSpan(
          text: displayString,
          style: TextStyle(color: context.theme.accent),
          mouseCursor: SystemMouseCursors.click,
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrlString(linkString),
        ),
      );

  @override
  List<Object?> get props => [];

  @override
  bool? get stringify => true;
}

class EmojiTextMatcher extends TextMatcher implements EquatableMixin {
  EmojiTextMatcher()
    : super.regExp(
        regExp: emojiRegex,
        matchBuilder: (span, displayString, linkString) => TextSpan(
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

  @override
  List<Object?> get props => [];

  @override
  bool? get stringify => true;
}

class KeyWordTextMatcher extends TextMatcher implements EquatableMixin {
  KeyWordTextMatcher(this.keyword, {this.style, this.caseSensitive = true})
    : super.regExp(
        regExp: RegExp(RegExp.escape(keyword), caseSensitive: caseSensitive),
        matchBuilder: (span, displayString, linkString) => TextSpan(
          text: displayString,
          style: style,
          recognizer: span.recognizer,
          mouseCursor: span.mouseCursor,
          onEnter: span.onEnter,
          onExit: span.onExit,
          semanticsLabel: span.semanticsLabel,
          locale: span.locale,
          spellOut: span.spellOut,
        ),
      );

  final String keyword;
  final TextStyle? style;
  final bool caseSensitive;

  @override
  List<Object?> get props => [keyword, style, caseSensitive];

  @override
  bool? get stringify => true;
}

class MultiKeyWordTextMatcher extends TextMatcher implements EquatableMixin {
  MultiKeyWordTextMatcher(
    this.keywords, {
    this.style,
    this.caseSensitive = true,
  }) : super.regExp(
         regExp: _createMultiKeywordRegExp(keywords, caseSensitive),
         matchBuilder: (span, displayString, linkString) => TextSpan(
           text: displayString,
           style: style,
           recognizer: span.recognizer,
           mouseCursor: span.mouseCursor,
           onEnter: span.onEnter,
           onExit: span.onExit,
           semanticsLabel: span.semanticsLabel,
           locale: span.locale,
           spellOut: span.spellOut,
         ),
       );

  final List<String> keywords;
  final TextStyle? style;
  final bool caseSensitive;

  static RegExp _createMultiKeywordRegExp(
    List<String> keywords,
    bool caseSensitive,
  ) {
    if (keywords.isEmpty) {
      return RegExp('(?!)'); // Never match
    }

    final escapedKeywords = keywords
        .where((k) => k.trim().isNotEmpty)
        .map((k) => RegExp.escape(k.trim()))
        .toList();

    if (escapedKeywords.isEmpty) {
      return RegExp('(?!)'); // Never match
    }

    final pattern = escapedKeywords.join('|');
    return RegExp('($pattern)', caseSensitive: caseSensitive);
  }

  @override
  List<Object?> get props => [keywords, style, caseSensitive];

  @override
  bool? get stringify => true;

  /// Creates a keyword text matcher based on the input string
  /// If the keyword contains spaces, it will return a MultiKeyWordTextMatcher
  /// Otherwise, it will return a KeyWordTextMatcher
  static TextMatcher createKeywordMatcher({
    required String keyword,
    TextStyle? style,
    bool caseSensitive = true,
  }) {
    if (keyword.trim().isEmpty) {
      throw ArgumentError('Keyword cannot be empty');
    }

    if (keyword.trim().contains(' ')) {
      return MultiKeyWordTextMatcher(
        keyword.trim().split(RegExp(r'\s+')),
        style: style,
        caseSensitive: caseSensitive,
      );
    } else {
      return KeyWordTextMatcher(
        keyword,
        style: style,
        caseSensitive: caseSensitive,
      );
    }
  }
}

class BotNumberTextMatcher extends TextMatcher implements EquatableMixin {
  BotNumberTextMatcher(BuildContext context)
    : super.regExp(
        regExp: botNumberRegExp,
        matchBuilder: (span, displayString, linkString) => TextSpan(
          text: displayString,
          style: TextStyle(color: context.theme.accent),
          mouseCursor: SystemMouseCursors.click,
          recognizer: TapGestureRecognizer()
            ..onTap = () => showUserDialog(context, null, linkString),
        ),
      );

  @override
  List<Object?> get props => [];

  @override
  bool? get stringify => true;
}

class MentionTextMatcher extends TextMatcher implements EquatableMixin {
  MentionTextMatcher(BuildContext context, this.map)
    : super.regExp(
        regExp: mentionNumberRegExp,
        matchBuilder: (span, displayString, linkString) {
          final mentionUser = map[linkString.substring(1)];
          if (displayString != linkString || mentionUser == null) {
            return TextSpan(text: linkString);
          }

          return TextSpan(
            text: '@${mentionUser.fullName ?? mentionUser.identityNumber}',
            style: TextStyle(color: context.theme.accent),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () => showUserDialog(
                context,
                null,
                mentionUser.identityNumber,
              ),
          );
        },
      );

  final Map<String, MentionUser> map;

  @override
  List<Object?> get props => [map];

  @override
  bool? get stringify => true;
}

class HighlightStarLinkText extends HookConsumerWidget {
  const HighlightStarLinkText(
    this.text, {
    required this.links,
    super.key,
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
    final spans = useMemoized(() {
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
    }, [text, highlightStyle, links]);
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}

class CustomSelectableArea extends StatelessWidget {
  const CustomSelectableArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SelectionArea(
    child: child,
    contextMenuBuilder: (context, state) => _SelectionAreaToolbar(state: state),
  );
}

class _SelectionAreaToolbar extends StatelessWidget {
  const _SelectionAreaToolbar({required this.state});

  final SelectableRegionState state;

  @override
  Widget build(BuildContext context) {
    if (!kPlatformIsDesktop) {
      return AdaptiveTextSelectionToolbar.selectableRegion(
        selectableRegionState: state,
      );
    }
    return _SelectionToolbar(
      menus: [
        if (state.copyEnabled)
          ContextMenu(
            title: MaterialLocalizations.of(context).copyButtonLabel,
            onTap: () {
              // ignore: deprecated_member_use
              state.copySelection(SelectionChangedCause.toolbar);
            },
          ),
        if (state.selectAllEnabled)
          ContextMenu(
            title: MaterialLocalizations.of(context).selectAllButtonLabel,
            onTap: state.selectAll,
          ),
      ],
      anchor: state.contextMenuAnchors.primaryAnchor,
    );
  }
}

class MixinAdaptiveSelectionToolbar extends StatelessWidget {
  const MixinAdaptiveSelectionToolbar({
    required this.editableTextState,
    super.key,
  });

  final EditableTextState editableTextState;

  @override
  Widget build(BuildContext context) {
    if (kPlatformIsDesktop) {
      return _SelectionToolbar(
        menus: [
          if (editableTextState.copyEnabled)
            ContextMenu(
              title: MaterialLocalizations.of(context).copyButtonLabel,
              onTap: () {
                editableTextState.copySelection(SelectionChangedCause.toolbar);
              },
            ),
          if (editableTextState.cutEnabled)
            ContextMenu(
              title: MaterialLocalizations.of(context).cutButtonLabel,
              onTap: () {
                editableTextState.cutSelection(SelectionChangedCause.toolbar);
              },
            ),
          if (editableTextState.selectAllEnabled)
            ContextMenu(
              title: MaterialLocalizations.of(context).selectAllButtonLabel,
              onTap: () {
                editableTextState.selectAll(SelectionChangedCause.toolbar);
              },
            ),
          if (editableTextState.pasteEnabled)
            ContextMenu(
              title: MaterialLocalizations.of(context).pasteButtonLabel,
              onTap: () {
                editableTextState.pasteText(SelectionChangedCause.toolbar);
              },
            ),
        ],
        anchor: editableTextState.contextMenuAnchors.primaryAnchor,
      );
    }
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({required this.menus, required this.anchor});

  final List<Widget> menus;
  final Offset anchor;

  @override
  Widget build(BuildContext context) => CustomSingleChildLayout(
    delegate: PositionedLayoutDelegate(position: anchor),
    child: ContextMenuPage(menus: menus),
  );
}

class _CustomRichText extends RichText {
  _CustomRichText({
    required super.text,
    super.textAlign = TextAlign.start,
    super.softWrap = true,
    super.overflow = TextOverflow.clip,
    super.textScaler = TextScaler.noScaling,
    super.maxLines,
    super.textWidthBasis = TextWidthBasis.parent,
    super.textHeightBehavior,
    super.selectionRegistrar,
    super.selectionColor,
  });

  @override
  RenderParagraph createRenderObject(BuildContext context) =>
      _CustomRenderParagraph(
        text,
        textAlign: textAlign,
        textDirection: textDirection ?? Directionality.of(context),
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        locale: locale ?? Localizations.maybeLocaleOf(context),
        registrar: selectionRegistrar,
        selectionColor: selectionColor,
      );
}

class _CustomRenderParagraph extends RenderParagraph {
  _CustomRenderParagraph(
    super.text, {
    required super.textDirection,
    super.softWrap = true,
    super.textAlign,
    super.overflow = TextOverflow.clip,
    super.maxLines,
    super.strutStyle,
    super.textScaler,
    super.textHeightBehavior,
    super.textWidthBasis,
    super.locale,
    super.registrar,
    super.selectionColor,
  });

  @override
  List<TextBox> getBoxesForSelection(
    TextSelection selection, {
    ui.BoxHeightStyle boxHeightStyle = ui.BoxHeightStyle.max,
    ui.BoxWidthStyle boxWidthStyle = ui.BoxWidthStyle.tight,
  }) => super.getBoxesForSelection(
    selection,
    boxHeightStyle: boxHeightStyle,
    boxWidthStyle: boxWidthStyle,
  );
}
