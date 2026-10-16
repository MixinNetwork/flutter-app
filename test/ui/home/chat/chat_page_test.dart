import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/home/chat/chat_history_viewport.dart';
import 'package:flutter_app/ui/home/chat/chat_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'syncMessageGlobalKeys preserves current keys and removes stale keys',
    () {
      final existingKey = GlobalKey(debugLabel: 'existing');
      final keysByMessageId = <String, GlobalKey>{
        'old': GlobalKey(debugLabel: 'old'),
        'existing': existingKey,
      };

      syncMessageGlobalKeys(keysByMessageId, {'existing', 'new'});

      expect(keysByMessageId.keys, unorderedEquals(['existing', 'new']));
      expect(keysByMessageId['existing'], same(existingKey));
      expect(keysByMessageId['new'], isA<GlobalKey>());
    },
  );

  testWidgets(
    'ChatBottomBarSwitcher keeps the input attached to the bottom while shrinking',
    (tester) async {
      const viewportKey = Key('viewport');
      const inputKey = Key('input');

      Future<void> pumpBottomBar(double inputHeight) => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            key: viewportKey,
            width: 320,
            height: 240,
            child: Column(
              children: [
                const Expanded(child: SizedBox()),
                ChatBottomBarSwitcher(
                  inMultiSelectMode: false,
                  inputContainer: SizedBox(
                    key: inputKey,
                    width: 320,
                    height: inputHeight,
                  ),
                  selectionBottomBar: const SizedBox(width: 320, height: 80),
                ),
              ],
            ),
          ),
        ),
      );

      await pumpBottomBar(140);
      await tester.pumpAndSettle();

      final viewportBottom = tester.getBottomLeft(find.byKey(viewportKey)).dy;
      expect(
        tester.getBottomLeft(find.byKey(inputKey)).dy,
        moreOrLessEquals(viewportBottom),
      );

      await pumpBottomBar(56);
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.getBottomLeft(find.byKey(inputKey)).dy,
        moreOrLessEquals(viewportBottom),
      );
    },
  );

  Future<void> pumpSwitcher(
    WidgetTester tester, {
    required bool inMultiSelectMode,
    required double inputHeight,
  }) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ChatBottomBarSwitcher(
          inMultiSelectMode: inMultiSelectMode,
          inputContainer: SizedBox(width: 320, height: inputHeight),
          selectionBottomBar: const SizedBox(width: 320, height: 80),
        ),
      ),
    ),
  );

  double barHeight(WidgetTester tester) =>
      tester.getSize(find.byType(ChatBottomBarSwitcher)).height;

  testWidgets('ChatBottomBarSwitcher grows with the input at once', (
    tester,
  ) async {
    await pumpSwitcher(tester, inMultiSelectMode: false, inputHeight: 56);
    await tester.pumpAndSettle();

    // A new line in the input: the bar takes the new height in the same
    // frame, so its clip does not cover the input's padding.
    await pumpSwitcher(tester, inMultiSelectMode: false, inputHeight: 76);
    await tester.pump(const Duration(milliseconds: 16));
    expect(barHeight(tester), 76);
  });

  testWidgets('ChatBottomBarSwitcher animates its height between bars', (
    tester,
  ) async {
    await pumpSwitcher(tester, inMultiSelectMode: false, inputHeight: 56);
    await tester.pumpAndSettle();

    await pumpSwitcher(tester, inMultiSelectMode: true, inputHeight: 56);
    await tester.pump(const Duration(milliseconds: 150));
    expect(barHeight(tester), inExclusiveRange(56, 80));
    await tester.pumpAndSettle();
    expect(barHeight(tester), 80);

    // After the switch, the input's lines change the height at once again.
    await pumpSwitcher(tester, inMultiSelectMode: false, inputHeight: 56);
    await tester.pumpAndSettle();
    await pumpSwitcher(tester, inMultiSelectMode: false, inputHeight: 96);
    await tester.pump(const Duration(milliseconds: 16));
    expect(barHeight(tester), 96);
  });
}
