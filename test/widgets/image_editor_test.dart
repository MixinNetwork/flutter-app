import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_app/ui/home/chat/image_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transform crop rect', () {
    final imageRect = Offset.zero & const Size(400, 400);
    final a = transformInsideRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      imageRect,
      0,
    );
    expect(a, const Rect.fromLTWH(0, 0, 100, 100));

    final c = transformInsideRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      imageRect,
      math.pi,
    );
    expect(c, const Rect.fromLTWH(300, 300, 100, 100));
    final d = transformInsideRect(c, imageRect, math.pi);
    expect(d.toString(), const Rect.fromLTWH(0, 0, 100, 100).toString());

    final e = transformInsideRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      imageRect,
      math.pi / 2,
    );
    expect(e.toString(), const Rect.fromLTWH(300, 0, 100, 100).toString());
    final f = transformInsideRect(e, imageRect, -math.pi / 2);
    expect(f.toString(), const Rect.fromLTWH(0, 0, 100, 100).toString());
  });
}
