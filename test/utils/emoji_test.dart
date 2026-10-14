import 'package:flutter_app/utils/emoji.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
