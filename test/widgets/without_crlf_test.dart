import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('withoutCrLf replaces CRLF in the text of every span', () {
    final recognizer = TapGestureRecognizer();
    addTearDown(recognizer.dispose);
    const style = TextStyle(fontSize: 12);
    final span = TextSpan(
      text: 'a\r\nb',
      style: style,
      children: [
        TextSpan(text: 'c\r\n\r\nd', recognizer: recognizer),
        const TextSpan(text: 'e\rf'),
      ],
    );

    final result = withoutCrLf(span) as TextSpan;

    expect(result.text, 'a\nb');
    expect(result.style, style);
    final children = result.children!.cast<TextSpan>();
    expect(children[0].text, 'c\n\nd');
    expect(children[0].recognizer, recognizer);
    // A lone CR does not break the line, so it stays.
    expect(identical(children[1], span.children![1]), isTrue);
  });

  test('withoutCrLf returns a span without CRLF unchanged', () {
    const span = TextSpan(text: 'a\nb', children: [TextSpan(text: 'c')]);
    expect(identical(withoutCrLf(span), span), isTrue);
  });
}
