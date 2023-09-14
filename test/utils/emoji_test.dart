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
      '😚'
    ]);
  });

  test('split emoji', () {
    const text = '🧐t😉his is😒 a😛😝 st😒ring🤩. 🙂😙😇😙😚';
    final emojis = <String>[];
    final texts = <String>[];
    text.splitEmoji(
      onEmoji: emojis.add,
      onText: texts.add,
    );
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
      '😚'
    ]);
    expect(texts, ['t', 'his is', ' a', ' st', 'ring', '. ']);
  });
}
