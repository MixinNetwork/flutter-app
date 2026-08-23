import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/global_image_cache.dart';
import 'package:flutter_app/widgets/media_image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() {
  test('uses a cached provider for NetworkImage', () {
    const url = 'https://example.com/avatar.png';
    final resolved = resolveMediaImageProvider(
      const NetworkImage(url, scale: 2),
      null,
    );

    expect(resolved, isA<CachedNetworkImage>());
    final image = resolved as CachedNetworkImage;
    expect(image.url, url);
    expect(image.scale, 2);
  });

  test('reuses decoded and persistent remote image caches', () async {
    const url = 'https://example.com/avatar.png';
    final image = img.Image(width: 1, height: 1)
      ..setPixelRgba(0, 0, 0, 0, 0, 255);
    final bytes = Uint8List.fromList(img.encodePng(image));
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    var calls = 0;
    Future<http.StreamedResponse> fetcher(_, _, _) async {
      calls += 1;
      return http.StreamedResponse(
        Stream.value(bytes),
        HttpStatus.ok,
        headers: {HttpHeaders.cacheControlHeader: 'max-age=3600'},
      );
    }

    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher,
      maxSizeBytes: 1024,
    );
    final first = CachedNetworkImage(url, imageCache: cache);
    expect((await _resolveImage(first)).synchronouslyLoaded, isFalse);
    expect(calls, 1);

    expect(
      (await _resolveImage(
        CachedNetworkImage(url, imageCache: cache),
      )).synchronouslyLoaded,
      isTrue,
    );
    expect(calls, 1);

    final restartedCache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher,
      maxSizeBytes: 1024,
    );
    await _resolveImage(CachedNetworkImage(url, imageCache: restartedCache));
    expect(calls, 1);
  });

  test('uses revalidated bytes for a stale source cache', () async {
    const url = 'https://example.com/avatar.png';
    final original = img.Image(width: 1, height: 1);
    final fresh = img.Image(width: 2, height: 1);
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final requestHeaders = <Map<String, String>>[];
    var calls = 0;
    Future<http.StreamedResponse> fetcher(
      _,
      _,
      Map<String, String> headers,
    ) async {
      requestHeaders.add(Map<String, String>.of(headers));
      switch (calls++) {
        case 0:
          return http.StreamedResponse(
            Stream.value(Uint8List.fromList(img.encodePng(original))),
            HttpStatus.ok,
            headers: {
              HttpHeaders.cacheControlHeader: 'no-cache',
              HttpHeaders.etagHeader: 'one',
            },
          );
        case 1:
          return http.StreamedResponse(
            Stream.value(Uint8List(0)),
            HttpStatus.notModified,
          );
        default:
          return http.StreamedResponse(
            Stream.value(Uint8List.fromList(img.encodePng(fresh))),
            HttpStatus.ok,
            headers: {
              HttpHeaders.cacheControlHeader: 'max-age=3600',
              HttpHeaders.etagHeader: 'two',
            },
          );
      }
    }

    Future<_ResolvedImage> loadWithNewCache() => _resolveImage(
      CachedNetworkImage(
        url,
        imageCache: GlobalImageCache.forTesting(
          directory: directory,
          fetcher: fetcher,
          maxSizeBytes: 1024,
        ),
      ),
    );

    expect((await loadWithNewCache()).width, 1);
    expect((await loadWithNewCache()).width, 1);
    expect(requestHeaders[1][HttpHeaders.ifNoneMatchHeader], 'one');
    expect((await loadWithNewCache()).width, 2);
    expect(requestHeaders[2][HttpHeaders.ifNoneMatchHeader], 'one');
    expect((await loadWithNewCache()).width, 2);
    expect(calls, 3);
  });

  testWidgets('keeps file images out of the remote image provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaImagePipeline(
          image: FileImage(File.fromUri(Uri())),
        ),
      ),
    );

    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isNot(isA<CachedNetworkImage>()),
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

Future<_ResolvedImage> _resolveImage(ImageProvider image) {
  final stream = image.resolve(ImageConfiguration.empty);
  final completer = Completer<_ResolvedImage>();
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, synchronouslyLoaded) {
      final width = image.image.width;
      image.dispose();
      stream.removeListener(listener);
      completer.complete(
        _ResolvedImage(
          width: width,
          synchronouslyLoaded: synchronouslyLoaded,
        ),
      );
    },
    onError: (error, stackTrace) {
      stream.removeListener(listener);
      completer.completeError(error, stackTrace);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

class _ResolvedImage {
  const _ResolvedImage({
    required this.width,
    required this.synchronouslyLoaded,
  });

  final int width;
  final bool synchronouslyLoaded;
}
