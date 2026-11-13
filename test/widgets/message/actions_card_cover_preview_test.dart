import 'package:drift/native.dart';
import 'package:flutter/painting.dart' show NetworkImage;
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

void main() {
  Future<void> pumpCard(WidgetTester tester, AppCardData data) async {
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

  testWidgets('cover_url opens a zoomable network preview and closes', (
    tester,
  ) async {
    const url = 'https://example.com/cover-url.png';
    await pumpCard(tester, card(coverUrl: url));

    await tester.tap(find.byType(MixinImage).first);
    await tester.pumpAndSettle();

    expect(find.byType(ImagPreviewWidget), findsOneWidget);
    expect(
      (tester.widget<MixinImage>(find.byType(MixinImage).last).image
              as NetworkImage)
          .url,
      url,
    );
    final controller = tester.widget<ImagPreviewWidget>(
      find.byType(ImagPreviewWidget),
    ).controller!;
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is ActionButton &&
            widget.name == Resources.assetsImagesZoomInSvg,
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.scale, greaterThan(1));

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is ActionButton &&
            widget.name == Resources.assetsImagesIcCloseBigSvg,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ImagPreviewWidget), findsNothing);
  });

  testWidgets('cover.url opens the same preview and Escape closes it', (
    tester,
  ) async {
    const url = 'https://example.com/cover-object.png';
    await pumpCard(
      tester,
      card(
        cover: const Cover(
          url: url,
          thumbnail: null,
          mimeType: 'image/png',
          width: 640,
          height: 320,
        ),
      ),
    );

    await tester.tap(find.byType(MixinImage).first);
    await tester.pumpAndSettle();
    expect(find.byType(ImagPreviewWidget), findsOneWidget);
    expect(
      (tester.widget<MixinImage>(find.byType(MixinImage).last).image
              as NetworkImage)
          .url,
      url,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ImagPreviewWidget), findsNothing);
  });
}
