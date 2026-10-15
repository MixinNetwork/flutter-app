import 'dart:io';

import 'package:data_detector/data_detector.dart';
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

  test('mayContainUrl follows the iOS app check', () {
    for (final (text, expected) in [
      ('', false),
      ('收到', false),
      ('10:30 开会', false),
      ('tel:123 skype:foo', false),
      ('a.b', false),
      ('a.bc', true),
      ('mixin.one', true),
      ('see https://x', true),
      ('end. Next', false),
      ('a..b', false),
      ('今天。明天', false),
      ('见 mixin.one/blog', true),
    ]) {
      expect(mayContainUrl(text), expected, reason: text);
    }
  });

  test(
    'darwin link ranges match NSDataDetector where a link can be',
    () {
      final detector = DataDetector(NSTextCheckingType.NSTextCheckingTypeLink);
      for (final text in [
        '收到',
        '今天下午三点在会议室讨论一下新版本的发布计划。',
        'example。com 例子。中国 example．com',
        'see https://mixin.one/blog and a@b.com',
        'tel:123 skype:foo news:comp.lang file:///tmp mixin://users/1',
        'http：//a.com 时间 10:30',
        'localhost www wwwexample a@b',
      ]) {
        expect(
          darwinLinkRanges(text),
          mayContainUrl(text)
              ? detector.matchesInString(text).map((e) => e.range).toList()
              : isEmpty,
          reason: text,
        );
      }
    },
    skip: !Platform.isMacOS,
  );

  test(
    'prepareLinkRanges finds links in the background',
    () async {
      final body = List.filled(30, '今天下午三点讨论发布计划，').join();
      final texts = [
        for (var i = 0; i < 20; i++)
          '$body see https://mixin.one/blog/$i for details.',
      ];
      expect(texts.any(linkRangesReady), isFalse);

      await prepareLinkRanges(texts);

      expect(texts.every(linkRangesReady), isTrue);
      final detector = DataDetector(NSTextCheckingType.NSTextCheckingTypeLink);
      for (final text in texts) {
        expect(
          darwinLinkRanges(text),
          detector.matchesInString(text).map((e) => e.range).toList(),
        );
      }
    },
    skip: !Platform.isMacOS,
  );
}
