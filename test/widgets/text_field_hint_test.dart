import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/constants/brightness_theme_data.dart';
import 'package:flutter_app/widgets/brightness_observer.dart';
import 'package:flutter_app/widgets/search_text_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    testWidgets('caret does not cover the hint on ${platform.name}', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: BrightnessData(
            value: 0,
            brightnessThemeData: lightBrightnessThemeData,
            child: MaterialApp(
              theme: ThemeData(platform: platform),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 240,
                    child: SearchTextField(
                      controller: controller,
                      hintText: 'Search',
                      autofocus: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final editable = tester.allRenderObjects
          .whereType<RenderEditable>()
          .single;
      final caret = editable.getLocalRectForCaret(
        const TextPosition(offset: 0),
      );
      final caretRight = editable.localToGlobal(caret.topRight).dx;
      final hintLeft = tester.getTopLeft(find.text('Search')).dx;
      expect(caret.width, greaterThan(0));
      expect(caretRight, lessThanOrEqualTo(hintLeft));
    });
  }
}
