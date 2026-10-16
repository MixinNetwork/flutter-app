import 'package:emojis/emoji.dart';
import 'package:flutter_app/utils/emoji.dart';
import 'package:flutter_test/flutter_test.dart';

List<(int, int)> _regexRanges(String text) => [
  for (final match in emojiRegex.allMatches(text))
    if (isTextStyleEmoji(match[0]!)) (match.start, match.end),
];

List<(int, int)> _ranges(String text) => [
  for (final range in textStyleEmojiRanges(text)) (range.start, range.end),
];

void main() {
  test('extract emoji', () {
    const text = '🧐t😉his is😒 a😛😝 st😒ring🤩. 🙂😙😇😙😚';
    final emojis = extractEmoji(text);
    expect(emojis, [
      '🧐',
      '😉',
      '😒',
      '😛',
      '😝',
      '😒',
      '🤩',
      '🙂',
      '😙',
      '😇',
      '😙',
      '😚',
    ]);
    final result2 = extractEmoji('👮👮‍♀️👮‍♂️');
    expect(result2, ['👮', '👮‍♀️', '👮‍♂️']);
  });

  test('split emoji only splits emoji that text fonts also draw', () {
    const text = '🧐t❤️his ☕ is😒 1️⃣';
    final emojis = <String>[];
    final texts = <String>[];
    text.splitEmoji(onEmoji: emojis.add, onText: texts.add);
    expect(emojis, ['❤️', '☕', '1️⃣']);
    expect(texts, ['🧐t', 'his ', ' is😒 ']);
  });

  test(
    'mayContainTextStyleEmoji skips plain Chinese and supplementary emoji',
    () {
      expect(mayContainTextStyleEmoji('今天下午三点开会，大家记得带电脑。'), isFalse);
      expect(mayContainTextStyleEmoji('hello 😀🎉'), isFalse);
      expect(mayContainTextStyleEmoji('好的 ❤️'), isTrue);
      expect(mayContainTextStyleEmoji('☕'), isTrue);
    },
  );

  test('finds the same text-style emoji as the emoji regular expression', () {
    final mismatches = <String>[];
    for (final emoji in Emoji.all()) {
      for (final text in ['a${emoji.char}b', '中${emoji.char}${emoji.char}文']) {
        if ('${_regexRanges(text)}' != '${_ranges(text)}') {
          mismatches.add(emoji.char);
        }
      }
    }
    expect(mismatches, isEmpty);
  });

  test('finds text-style emoji in mixed text', () {
    const text = '❤️ok ☺️ 1️⃣ ©️ 😀 #️⃣ 汉字 ✌🏻 ❤️‍🔥 ™️';
    expect(_ranges(text), _regexRanges(text));
    expect(_ranges(text), isNotEmpty);
  });
}
