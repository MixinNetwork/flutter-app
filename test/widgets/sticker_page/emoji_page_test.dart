import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/account/account_key_value.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/generated/l10n.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/sticker_page/emoji_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:provider/provider.dart' as provider;

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('emoji_page');
    Hive.init(directory.path);
    AccountKeyValue.instance.box = await Hive.openBox('account_box');
  });

  testWidgets('the emoji grid draws images and inserts a tapped emoji', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    // Emoji images render while an animation runs.
    warmEmojiPage(3);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            Localization.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: BrightnessData(
            value: 0,
            brightnessThemeData: lightBrightnessThemeData,
            child: provider.ChangeNotifierProvider.value(
              value: controller,
              child: const Material(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(),
                    SizedBox(width: 400, height: 400, child: EmojiPage()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Scheduler tasks lay the emoji out, and the raster thread renders them.
    Future<void> renderImages() async {
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 1));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      await tester.pump();
    }

    await renderImages();

    expect(emojiImageReady('😀'), isTrue);
    // Images render a few at a time, so the raster thread is not held.
    expect(largestEmojiImageBatch, inInclusiveRange(1, 3));
    expect(find.semantics.byLabel('😀'), findsOne);

    tester.semantics.tap(find.semantics.byLabel('😀'));
    expect(controller.text, '😀');

    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    // The warm-up starts after 2 s.
    await tester.pump(const Duration(seconds: 3));
    await renderImages();
    // The warm-up also reads the icons of the sticker album bar, which this
    // page does not show.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    expect(
      svg.cache.evict(
        const SvgAssetLoader(
          Resources.assetsImagesGifStickerSvg,
        ).cacheKey(null),
      ),
      isTrue,
    );
  });
}
