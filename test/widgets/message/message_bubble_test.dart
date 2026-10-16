import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/message/message_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a bubble casts the shadow of its body, not its nip', (
    tester,
  ) async {
    const size = Size(200, 40);
    final clipper = BubbleClipper(currentUser: false, showNip: true);
    final clip = clipper.getClip(size);
    final body = clipper.bodyRRect(size);
    Offset? nip;
    for (var y = 0.0; y < size.height && nip == null; y += 0.5) {
      for (var x = 0.0; x < size.width && nip == null; x += 0.5) {
        final point = Offset(x, y);
        if (clip.contains(point) && !body.contains(point)) nip = point;
      }
    }
    expect(nip, isNotNull);

    await tester.pumpWidget(
      Center(
        child: CustomPaint(
          size: size,
          painter: BubblePainter(color: Colors.white, clipper: clipper),
        ),
      ),
    );

    expect(
      find.byType(CustomPaint),
      paints
        ..shadow(includes: [body.center], excludes: [nip!])
        ..path(includes: [body.center, nip]),
    );
  });
}
