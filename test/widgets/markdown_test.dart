import 'package:flutter/material.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/markdown.dart';
import 'package:flutter_app/widgets/message/item/post_message.dart';
import 'package:flutter_app/widgets/message/message_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mixin_markdown_widget/mixin_markdown_widget.dart'
    as mixin_markdown;

void main() {
  testWidgets('renders PostMessage Markdown with mixin_markdown_widget', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const MarkdownColumn(data: '# Post title')));

    expect(tester.takeException(), isNull);
    expect(find.byType(mixin_markdown.MarkdownWidget), findsOneWidget);
    expect(find.text('Post title'), findsOneWidget);
  });

  testWidgets('allows a 1200px Markdown preview width', (tester) async {
    await tester.pumpWidget(
      _app(
        const Markdown(
          data: '# Post title',
          maxContentWidth: 1200,
        ),
      ),
    );

    final markdown = tester.widget<mixin_markdown.MarkdownWidget>(
      find.byType(mixin_markdown.MarkdownWidget),
    );

    expect(markdown.theme!.maxContentWidth, 1200);
  });

  testWidgets('scales PostMessage H1 once with the chat font setting', (
    tester,
  ) async {
    const chatFontSizeDelta = 4.0;
    await tester.pumpWidget(
      _app(
        const MarkdownColumn(data: '# Post title'),
        chatFontSizeDelta: chatFontSizeDelta,
      ),
    );

    final markdown = tester.widget<mixin_markdown.MarkdownWidget>(
      find.byType(mixin_markdown.MarkdownWidget),
    );
    final context = tester.element(find.byType(mixin_markdown.MarkdownWidget));
    final base = mixin_markdown.MarkdownThemeData.themed(context);
    final scale =
        (MessageStyle.defaultStyle.primaryFontSize + chatFontSizeDelta) /
        (base.bodyStyle.fontSize ?? MessageStyle.defaultStyle.primaryFontSize);

    expect(
      markdown.theme!.heading1Style.fontSize,
      closeTo((base.heading1Style.fontSize ?? 0) * scale, 0.001),
    );
  });

  testWidgets('renders a post draft without MessageContext', (tester) async {
    await tester.pumpWidget(
      _app(
        const MessagePost(
          showStatus: false,
          clickable: false,
          content: '# Draft post',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Draft post'), findsOneWidget);
  });

  test('updates a cached controller when post content changes', () {
    final cache = MarkdownControllerCache();
    final initial = cache.acquire('post:message', 'old content');
    final updated = cache.acquire('post:message', 'new content');

    expect(updated, same(initial));
    expect(updated.data, 'new content');
    expect(updated.plainText, 'new content');

    cache
      ..release('post:message', initial)
      ..release('post:message', updated);
  });

  testWidgets('releases a cached controller after PostMessage updates', (
    tester,
  ) async {
    const key = 'post:widget-cache';
    final initial = markdownControllerCache.acquire(key, 'version 0');
    markdownControllerCache.release(key, initial);

    for (var version = 1; version <= 120; version += 1) {
      await tester.pumpWidget(
        _app(MarkdownColumn(data: 'version $version', cacheKey: key)),
      );
    }
    await tester.pumpWidget(_app(const SizedBox()));

    for (var index = 0; index < 120; index += 1) {
      final other = markdownControllerCache.acquire(
        'post:widget-cache-$index',
        'other $index',
      );
      markdownControllerCache.release('post:widget-cache-$index', other);
    }

    final replacement = markdownControllerCache.acquire(key, 'version 120');

    expect(replacement, isNot(same(initial)));

    markdownControllerCache.release(key, replacement);
  });
}

Widget _app(
  Widget child, {
  double chatFontSizeDelta = 0,
}) => ProviderScope(
  overrides: [
    settingProvider.overrideWith(
      (ref) => SettingChangeNotifier(chatFontSizeDelta: chatFontSizeDelta),
    ),
  ],
  child: MaterialApp(
    home: BrightnessData(
      value: 0,
      brightnessThemeData: lightBrightnessThemeData,
      child: Scaffold(body: child),
    ),
  ),
);
