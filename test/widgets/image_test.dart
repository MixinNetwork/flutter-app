import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';

  RawImage raw() => find.byType(RawImage).evaluate().single.widget as RawImage;

  testWidgets('blur hash decodes off the frame and then shows at once', (
    tester,
  ) async {
    await tester.pumpWidget(const ImageByBlurHashOrBase64(imageData: hash));
    expect(raw().image, isNull);

    await tester.runAsync(() async {
      for (var i = 0; i < 100 && raw().image == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(raw().image?.width, 20);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const ImageByBlurHashOrBase64(imageData: hash));
    expect(raw().image?.width, 20);
  });
}
