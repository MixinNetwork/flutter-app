import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/clamping_custom_scroll_view/clamping_custom_scroll_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'does not preserve bottom tracking across center changes',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      Widget buildScroll({
        required Key centerKey,
        required double bottomHeight,
      }) => Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 600,
          width: 400,
          child: ClampingCustomScrollView(
            controller: controller,
            center: centerKey,
            anchor: 0.3,
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              SliverToBoxAdapter(
                key: centerKey,
                child: const SizedBox(height: 100),
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottomHeight)),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        buildScroll(
          centerKey: const ValueKey('old-window'),
          bottomHeight: 3000,
        ),
      );
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(controller.offset, controller.position.maxScrollExtent);

      const newCenterKey = ValueKey('new-window');
      await tester.pumpWidget(
        buildScroll(centerKey: newCenterKey, bottomHeight: 3000),
      );
      await tester.pump();

      controller.jumpTo(500);
      await tester.pump();
      expect(controller.offset, 500);

      await tester.pumpWidget(
        buildScroll(centerKey: newCenterKey, bottomHeight: 3001),
      );
      await tester.pump();

      expect(controller.offset, 500);
    },
  );
}
