import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/message/message_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a bubble stretches a shadow image instead of a path shadow', (
    tester,
  ) async {
    for (final currentUser in [false, true]) {
      await tester.pumpWidget(
        Center(
          child: CustomPaint(
            size: const Size(200, 40),
            painter: BubblePainter(
              color: Colors.white,
              clipper: BubbleClipper(
                currentUser: currentUser,
                showNip: true,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byType(CustomPaint),
        paints
          ..something((method, arguments) => method == #drawVertices)
          ..path(),
      );
      expect(
        find.byType(CustomPaint),
        isNot(paints..shadow()),
      );
    }
  });

  test('clippers that differ only in nip padding are not equal', () {
    expect(
      BubbleClipper(currentUser: false, showNip: false),
      isNot(
        BubbleClipper(currentUser: false, showNip: false, nipPadding: false),
      ),
    );
  });
}
