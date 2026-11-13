import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/services.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/constants/resources.dart';
import 'package:flutter_app/db/database.dart';
import 'package:flutter_app/db/fts_database.dart';
import 'package:flutter_app/db/mixin_database.dart';
import 'package:flutter_app/ui/provider/database_provider.dart';
import 'package:flutter_app/ui/provider/setting_provider.dart';
import 'package:flutter_app/widgets/action_button.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/media_image_pipeline.dart';
import 'package:flutter_app/widgets/message/item/action_card/action_card_data.dart';
import 'package:flutter_app/widgets/message/item/action_card/actions_card.dart';
import 'package:flutter_app/widgets/message/item/image/preview_image_widget.dart';
import 'package:flutter_app/widgets/mixin_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _TestDatabaseOpener extends DatabaseOpener {
  _TestDatabaseOpener(Database database) {
    state = AsyncValue.data(database);
  }
}

const _imageWidth = 2000;
const _imageHeight = 1000;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  tearDown(() => PaintingBinding.instance.imageCache.clear());

  // The preview and the card load the image through CachedNetworkImage.
  Future<void> cacheImage(WidgetTester tester, String url) async {
    final image = await tester.runAsync(
      () => createTestImage(width: _imageWidth, height: _imageHeight),
    );
    PaintingBinding.instance.imageCache.putIfAbsent(
      CachedNetworkImage(url),
      () => OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image!)),
      ),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    AppCardData data, {
    bool previewCover = true,
  }) async {
    final database = Database(
      MixinDatabase(NativeDatabase.memory()),
      FtsDatabase(NativeDatabase.memory()),
    );
    addTearDown(database.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => _TestDatabaseOpener(database)),
          settingProvider.overrideWith((ref) => SettingChangeNotifier()),
        ],
        child: BrightnessData(
          value: 0,
          brightnessThemeData: lightBrightnessThemeData,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: ActionsCardBody(
                    data: data,
                    previewCover: previewCover,
                    description: const Text('description'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppCardData card({String coverUrl = '', Cover? cover}) => AppCardData(
    '',
    '',
    'title',
    'description',
    '',
    '',
    true,
    const [],
    coverUrl,
    cover,
  );

  Finder button(String name) => find.byWidgetPredicate(
    (widget) => widget is ActionButton && widget.name == name,
  );

  Future<void> openPreview(WidgetTester tester) async {
    await tester.tap(find.byType(MixinImage).first);
    await tester.pumpAndSettle();
  }

  testWidgets('cover_url opens at the scale that fits the image', (
    tester,
  ) async {
    const url = 'https://example.com/cover-url.png';
    await cacheImage(tester, url);
    await pumpCard(tester, card(coverUrl: url));
    await openPreview(tester);

    final preview = tester.widget<ImagPreviewWidget>(
      find.byType(ImagPreviewWidget),
    );
    final viewport = tester.getSize(find.byType(ImagPreviewWidget));
    final fit = math.min(
      viewport.width / _imageWidth,
      viewport.height / _imageHeight,
    );
    expect(preview.scale, fit);
    // The image zooms to twice its own size, not to twice the fitted size.
    expect(preview.maxScale, 2);

    await tester.tap(button(Resources.assetsImagesZoomInSvg));
    await tester.pumpAndSettle();
    expect(preview.controller!.scale, greaterThan(fit));

    await tester.tap(button(Resources.assetsImagesIcCloseBigSvg));
    await tester.pumpAndSettle();
    expect(find.byType(ImagPreviewWidget), findsNothing);
  });

  testWidgets('cover.url preview closes with Escape and on an empty area', (
    tester,
  ) async {
    const url = 'https://example.com/cover-object.png';
    await cacheImage(tester, url);
    final data = card(
      cover: const Cover(
        url: url,
        thumbnail: null,
        mimeType: 'image/png',
        width: _imageWidth,
        height: _imageHeight,
      ),
    );
    await pumpCard(tester, data);

    await openPreview(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ImagPreviewWidget), findsNothing);

    await openPreview(tester);
    // The fitted image is wider than the viewport is tall, so the bottom-left
    // corner is empty.
    await tester.tapAt(
      tester.getBottomLeft(find.byType(ImagPreviewWidget)).translate(4, -4),
    );
    // The double tap that resets the zoom waits for its timeout first.
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.byType(ImagPreviewWidget), findsNothing);
  });

  testWidgets('a card body without previewCover keeps the cover inert', (
    tester,
  ) async {
    const url = 'https://example.com/cover-inert.png';
    await cacheImage(tester, url);
    await pumpCard(tester, card(coverUrl: url), previewCover: false);

    await openPreview(tester);
    expect(find.byType(ImagPreviewWidget), findsNothing);
  });
}
