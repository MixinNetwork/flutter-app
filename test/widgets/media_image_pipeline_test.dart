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

}
