// ignore_for_file: avoid_print
import 'dart:math';

import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/extension/extension.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Measures TextPainter.layout for message-like text, one new string per
// layout so no paragraph cache helps.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const common =
      '的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处府';
  const emojis = ['😀', '👍🏻', '🎉', '🚀', '🔥', '❤️'];
  final random = Random(1);
  String chinese(int length) => List.generate(
    length,
    (_) => common[random.nextInt(common.length)],
  ).join();
  String withEmoji(int length) {
    final s = chinese(length);
    return '${s.substring(0, length ~/ 3)}${emojis[random.nextInt(6)]}'
        '${s.substring(length ~/ 3)} ${emojis[random.nextInt(6)]}';
  }

  final emojiMatchers = <TextMatcher>[EmojiTextMatcher()];
  const style = TextStyle(fontSize: 14, color: Colors.black);

  double measure(
    String label,
    InlineSpan Function(int i) span, {
    int? maxLines = 1,
    double width = 220,
  }) {
    // Warm up the fonts so one-time loading stays out of the numbers.
    for (var i = 0; i < 20; i++) {
      TextPainter(
        text: span(i),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      ).layout(maxWidth: width);
    }
    const n = 300;
    final watch = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      TextPainter(
        text: span(i),
        textDirection: TextDirection.ltr,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      ).layout(maxWidth: width);
    }
    final us = watch.elapsedMicroseconds / n;
    print('[layout] ${label.padRight(40)} ${us.toStringAsFixed(0)} us');
    return us;
  }

  testWidgets('text layout cost', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    const cjk = TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontFamily: 'Noto Sans CJK SC',
    );
    measure(
      'plain 40, fontFamily Noto Sans CJK SC',
      (i) => TextSpan(text: chinese(40), style: cjk),
    );
    measure(
      'plain 40, CJK + emoji spans',
      (i) => TextSpan(
        style: cjk,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: withEmoji(40)),
        ], emojiMatchers).toList(),
      ),
    );
    TextMatcher emojiFont(String? family) => TextMatcher.regExp(
      regExp: emojiRegex,
      matchBuilder: (span, display, link) => TextSpan(
        text: display,
        style: family == null ? null : TextStyle(fontFamily: family),
      ),
    );
    const simpleEmojis = ['😀', '🎉', '🚀', '🔥'];
    String withSimpleEmoji(int length) {
      final s = chinese(length);
      return '${s.substring(0, length ~/ 3)}${simpleEmojis[random.nextInt(4)]}'
          '${s.substring(length ~/ 3)} ${simpleEmojis[random.nextInt(4)]}';
    }

    measure(
      'CJK + simple emoji, bundled font',
      (i) => TextSpan(
        style: cjk,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: withSimpleEmoji(40)),
        ], emojiMatchers).toList(),
      ),
    );
    const cjkWithFallback = TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontFamily: 'Noto Sans CJK SC',
      fontFamilyFallback: [
        'NotoColorEmoji',
        'Noto Color Emoji',
        'Noto Sans',
        'Noto Sans Symbols',
        'Noto Sans Symbols 2',
      ],
    );
    measure(
      'CJK + emoji, fallback list, no span',
      (i) => TextSpan(text: withEmoji(40), style: cjkWithFallback),
    );
    measure(
      'CJK + emoji, fallback list + spans',
      (i) => TextSpan(
        style: cjkWithFallback,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: withEmoji(40)),
        ], emojiMatchers).toList(),
      ),
    );
    measure(
      'fallback list + spans without family',
      (i) => TextSpan(
        style: cjkWithFallback,
        children: TextMatcher.applyTextMatchers(
          [TextSpan(text: withEmoji(40))],
          [emojiFont(null)],
        ).toList(),
      ),
    );
    measure(
      'latin default + CJK/emoji fallback, mixed',
      (i) => TextSpan(
        text: 'hello ${withEmoji(30)} world',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontFamilyFallback: ['Noto Sans CJK SC', 'NotoColorEmoji'],
        ),
      ),
    );
    measure(
      'default family, fallback list CJK first',
      (i) => TextSpan(
        text: withEmoji(40),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontFamilyFallback: [
            'Noto Sans CJK SC',
            'NotoColorEmoji',
            'Noto Color Emoji',
          ],
        ),
      ),
    );
    for (final (label, family) in [
      ('bundled COLRv1 NotoColorEmoji', 'NotoColorEmoji'),
      ('system bitmap Noto Color Emoji', 'Noto Color Emoji'),
      ('no emoji font (fallback)', null),
    ]) {
      final matchers = [emojiFont(family)];
      measure(
        'CJK + emoji: $label',
        (i) => TextSpan(
          style: cjk,
          children: TextMatcher.applyTextMatchers([
            TextSpan(text: withEmoji(40)),
          ], matchers).toList(),
        ),
      );
    }
    const latin = TextStyle(
      fontSize: 14,
      color: Colors.black,
      fontFamily: 'Noto Sans',
    );
    measure(
      'latin 40, fontFamily Noto Sans',
      (i) =>
          TextSpan(text: 'The quick brown fox jumps over ${i}x', style: latin),
    );
    measure(
      'latin 40, default family',
      (i) =>
          TextSpan(text: 'The quick brown fox jumps over ${i}x', style: style),
    );
    measure(
      'plain 40 chars, 1 line',
      (i) => TextSpan(text: chinese(40), style: style),
    );
    measure(
      'plain 40 chars + overflow',
      (i) => TextSpan(text: chinese(40).overflow, style: style),
    );
    measure(
      'emoji spans 40 chars',
      (i) => TextSpan(
        style: style,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: withEmoji(40)),
        ], emojiMatchers).toList(),
      ),
    );
    measure(
      'emoji spans + overflow (list preview)',
      (i) => TextSpan(
        style: style,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: withEmoji(40).overflow),
        ], emojiMatchers).toList(),
      ),
    );
    measure(
      'plain 200 chars, wrap 600',
      (i) => TextSpan(text: chinese(200), style: style),
      maxLines: null,
      width: 600,
    );
    measure(
      'emoji spans 200 chars, wrap 600',
      (i) => TextSpan(
        style: style,
        children: TextMatcher.applyTextMatchers([
          TextSpan(text: withEmoji(200)),
        ], emojiMatchers).toList(),
      ),
      maxLines: null,
      width: 600,
    );
  }, semanticsEnabled: false);
}
