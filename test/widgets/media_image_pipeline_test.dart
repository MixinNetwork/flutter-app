import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/global_image_cache.dart';
import 'package:flutter_app/widgets/media_image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() {
  testWidgets('shows a resident remote image without its placeholder', (
    tester,
  ) async {
    const url = 'https://example.com/avatar.png';
    final image = img.Image(width: 1, height: 1)
      ..setPixelRgba(0, 0, 0, 0, 0, 255);
    final data = Uint8List.fromList(img.encodePng(image));
    late Directory directory;
    late GlobalImageCache cache;
    late Uint8List bytes;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('image-cache-test');
      cache = GlobalImageCache.forTesting(
        directory: directory,
        fetcher: (_, _, _) async => http.StreamedResponse(
          Stream.value(data),
          HttpStatus.ok,
          headers: {HttpHeaders.cacheControlHeader: 'max-age=3600'},
        ),
        maxSizeBytes: 1024,
      );
      bytes = await cache.getBytes(url, limitBytes: true).single;
    });
    addTearDown(() => directory.deleteSync(recursive: true));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        MemoryImage(bytes),
        tester.element(find.byType(SizedBox)),
      ),
    );
    await tester.pump();

    Widget imageFor(String imageUrl) => Directionality(
      textDirection: TextDirection.ltr,
      child: CachedMediaImage(
        url: imageUrl,
        scale: 1,
        proxyConfig: null,
        placeholder: () => const SizedBox(key: Key('placeholder')),
        errorBuilder: null,
        width: null,
        height: null,
        fit: null,
        isAntiAlias: false,
        imageCache: cache,
      ),
    );

    await tester.pumpWidget(imageFor(url));
    expect(find.byKey(const Key('placeholder')), findsNothing);

    await tester.pumpWidget(imageFor('https://example.com/other.png'));
    expect(find.byKey(const Key('placeholder')), findsOneWidget);
  });

  testWidgets('keeps file images out of the global cache', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaImagePipeline(
          image: FileImage(File.fromUri(Uri())),
        ),
      ),
    );

    expect(find.byType(CachedMediaImage), findsNothing);
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
