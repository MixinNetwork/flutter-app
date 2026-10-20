import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/interactive_decorated_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pointer moves rebuild only when hovering starts', (
    tester,
  ) async {
    var builds = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: InteractiveBuilder(
            builder: (context, status, lastStatus, child) {
              builds++;
              return const SizedBox(width: 100, height: 100);
            },
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    final center = tester.getCenter(find.byType(SizedBox));
    await gesture.moveTo(center);
    await tester.pump();
    final afterEnter = builds;
    for (var i = 1; i <= 5; i++) {
      await gesture.moveTo(center + Offset(i.toDouble(), 0));
      await tester.pump();
    }

    expect(builds, afterEnter);
  });

  testWidgets('animates only when a state decoration is set', (tester) async {
    Future<void> pump(Widget box) => tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: box),
    );

    await pump(InteractiveDecoratedBox(onTap: () {}, child: const SizedBox()));
    expect(find.byType(TweenAnimationBuilder<Decoration>), findsNothing);

    await pump(
      InteractiveDecoratedBox.color(
        decoration: const BoxDecoration(),
        hoveringColor: Colors.red,
        child: const SizedBox(),
      ),
    );
    expect(find.byType(TweenAnimationBuilder<Decoration>), findsOneWidget);
  });

  testWidgets('a child under IgnorePointer still takes taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: InteractiveDecoratedBox(
            onTap: () => taps++,
            behavior: HitTestBehavior.deferToChild,
            child: const IgnorePointer(
              child: SizedBox(width: 100, height: 20),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IgnorePointer), warnIfMissed: false);
    expect(taps, 1);
  });
}
