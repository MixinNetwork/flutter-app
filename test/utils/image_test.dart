import 'dart:typed_data';

import 'package:flutter_app/utils/image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('compressImage preserves transparency for alpha images', () {
    final source = img.Image(width: 2, height: 1, numChannels: 4)
      ..setPixelRgba(0, 0, 0, 0, 0, 0)
      ..setPixelRgba(1, 0, 255, 255, 255, 255);

    final encoded = Uint8List.fromList(img.encodePng(source));
    final result = compressImage(encoded);

    expect(result, isNotNull);

    final (bytes, type, _, _) = result!;
    final decoded = img.decodeImage(bytes);

    expect(type.mimeType, 'image/png');
    expect(decoded, isNotNull);
    expect(decoded!.getPixel(0, 0).a.toInt(), 0);
    expect(decoded.getPixel(1, 0).a.toInt(), 255);
  });
}
