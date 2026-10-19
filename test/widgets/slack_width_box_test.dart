import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/slack_width_box.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountLayouts extends SingleChildRenderObjectWidget {
  const _CountLayouts({required this.layouts, super.child});

  final List<double> layouts;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCountLayouts(layouts);
}

class _RenderCountLayouts extends RenderProxyBox {
  _RenderCountLayouts(this.layouts);

  final List<double> layouts;

  @override
  void performLayout() {
    layouts.add(constraints.maxWidth);
    super.performLayout();
  }
}

void main() {
  Widget frame({
    required double width,
    required double slack,
    required List<double> layouts,
  }) => Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        height: 100,
        child: SlackWidthBox(
          slack: slack,
          child: _CountLayouts(
            layouts: layouts,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  );

  testWidgets('lays out the child once while width plus slack stays the same', (
    tester,
  ) async {
    final layouts = <double>[];
    await tester.pumpWidget(frame(width: 300, slack: 0, layouts: layouts));
    expect(layouts, [300]);

    // A panel beside the box grows by 100 over a few frames.
    for (final width in [280.0, 250.0, 220.0, 200.0]) {
      await tester.pumpWidget(
        frame(width: width, slack: 300 - width, layouts: layouts),
      );
      expect(tester.getSize(find.byType(SlackWidthBox)).width, width);
    }
    expect(layouts, [300], reason: 'the child keeps one layout width');

    // At the end of the animation the child takes the width of the box.
    await tester.pumpWidget(frame(width: 200, slack: 0, layouts: layouts));
    expect(layouts, [300, 200]);
  });

  testWidgets('clips the part of the child beyond the box', (tester) async {
    await tester.pumpWidget(frame(width: 200, slack: 100, layouts: []));
    final box = tester.renderObject<RenderSlackWidthBox>(
      find.byType(SlackWidthBox),
    );
    expect(box.size.width, 200);
    expect(box.child!.size.width, 300);
    expect(
      find.byType(SlackWidthBox),
      paints..clipRect(rect: const Rect.fromLTWH(0, 0, 200, 100)),
    );
  });
}
