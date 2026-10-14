import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/high_light_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

var _matchCount = 0;

class _CountingMatcher extends TextMatcher with Equatable {
  _CountingMatcher()
    : super.textRangesFromText(
        textRangesFromText: (text) {
          _matchCount++;
          return const [];
        },
        matchBuilder: (span, displayString, linkString) => span,
      );

  @override
  List<Object?> get props => [];
}

Widget _scope(Widget child, {BrightnessThemeData? theme}) => ProviderScope(
  child: MaterialApp(
    home: BrightnessData(
      value: 0,
      brightnessThemeData: theme ?? lightBrightnessThemeData,
      child: Material(child: child),
    ),
  ),
);

void main() {
  setUp(() => _matchCount = 0);

  testWidgets('equal matchers reuse the matched spans on rebuild', (
    tester,
  ) async {
    await tester.pumpWidget(
      _scope(CustomText('hello', textMatchers: [_CountingMatcher()])),
    );
    await tester.pumpWidget(
      _scope(CustomText('hello', textMatchers: [_CountingMatcher()])),
    );
    expect(_matchCount, 1);
  });

  testWidgets('a new text, rich span or theme matches again', (tester) async {
    await tester.pumpWidget(
      _scope(CustomText('hello', textMatchers: [_CountingMatcher()])),
    );
    await tester.pumpWidget(
      _scope(CustomText('world', textMatchers: [_CountingMatcher()])),
    );
    expect(_matchCount, 2);

    await tester.pumpWidget(
      _scope(
        CustomText.rich(
          const TextSpan(text: 'a'),
          textMatchers: [_CountingMatcher()],
        ),
      ),
    );
    await tester.pumpWidget(
      _scope(
        CustomText.rich(
          const TextSpan(text: 'b'),
          textMatchers: [_CountingMatcher()],
        ),
      ),
    );
    expect(_matchCount, 4);

    await tester.pumpWidget(
      _scope(
        CustomText.rich(
          const TextSpan(text: 'b'),
          textMatchers: [_CountingMatcher()],
        ),
        theme: darkBrightnessThemeData,
      ),
    );
    expect(_matchCount, 5);
  });

  test('EmojiTextMatcher sets the emoji font only on text-style emoji', () {
    final spans = TextMatcher.applyTextMatchers(
      [
        const TextSpan(text: 'a😀b❤️‍🔥c'),
      ],
      [EmojiTextMatcher()],
    ).toList();
    final styled = <String>[];
    for (final span in spans) {
      span.visitChildren((child) {
        if (child is TextSpan && child.style?.fontFamily != null) {
          styled.add(child.text!);
        }
        return true;
      });
    }
    expect(styled, ['❤️‍🔥']);
  });
}
