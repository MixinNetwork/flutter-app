import 'package:flutter/painting.dart';
import 'package:flutter_app/ui/home/chat/image_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 400, 300);

  test('a corner drag keeps a square crop square', () {
    final rect = dragCropCornerWithRatio(
      moving: const Offset(200, 200),
      anchor: const Offset(100, 100),
      delta: const Offset(50, 10),
      bounds: bounds,
      ratio: 1,
    );
    expect(rect, const Rect.fromLTWH(100, 100, 150, 150));
  });

  test('the top left corner moves and the bottom right corner stays', () {
    final rect = dragCropCornerWithRatio(
      moving: const Offset(100, 100),
      anchor: const Offset(200, 200),
      delta: const Offset(-20, -40),
      bounds: bounds,
      ratio: 1,
    );
    expect(rect, const Rect.fromLTWH(60, 60, 140, 140));
  });

  test('the crop stays inside the image', () {
    final rect = dragCropCornerWithRatio(
      moving: const Offset(200, 200),
      anchor: const Offset(100, 100),
      delta: const Offset(500, 500),
      bounds: bounds,
      ratio: 1,
    );
    expect(rect, const Rect.fromLTWH(100, 100, 200, 200));
  });

  test('the crop does not get smaller than two handles', () {
    final rect = dragCropCornerWithRatio(
      moving: const Offset(200, 200),
      anchor: const Offset(100, 100),
      delta: const Offset(-300, -300),
      bounds: bounds,
      ratio: 1,
    );
    expect(rect, const Rect.fromLTWH(100, 100, 60, 60));
  });
}
