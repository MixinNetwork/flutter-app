import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_app/widgets/media_image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses custom media pipeline only for proxy or likely gif urls', () {
    expect(
      shouldUseMediaImagePipeline('https://example.com/a.png', null),
      false,
    );
    expect(
      shouldUseMediaImagePipeline('https://example.com/a.gif?x=1', null),
      true,
    );
    expect(
      shouldUseMediaImagePipeline(
        'https://example.com/no-extension',
        null,
        normalizeGif: true,
      ),
      true,
    );
    expect(
      shouldUseMediaImagePipeline(
        'https://example.com/a.png',
        ProxyConfig(
          type: ProxyType.http,
          host: '127.0.0.1',
          port: 8080,
          id: 'test',
        ),
      ),
      true,
    );
  });

  testWidgets('skips file images with empty paths', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NormalizedGifImageGate(
          image: FileImage(File.fromUri(Uri())),
          placeholder: () => const SizedBox.shrink(),
          childBuilder: () => const SizedBox(key: Key('child')),
        ),
      ),
    );

    expect(find.byKey(const Key('child')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
