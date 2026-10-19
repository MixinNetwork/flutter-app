import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/widgets/global_image_cache.dart';
import 'package:flutter_app/widgets/media_image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() {
  group('coverDecodeImage', () {
    final images = <String, Uint8List>{};
    Future<(int, int)> decode(
      Size box,
      int width,
      int height, {
      int orientation = 1,
    }) async {
      final bytes = images.putIfAbsent('$width $height $orientation', () {
        final image = img.Image(width: width, height: height);
        image.exif.imageIfd.orientation = orientation;
        return Uint8List.fromList(img.encodeJpg(image));
      });
      final resolved = await _resolveImage(
        coverDecodeImage(MemoryImage(bytes), box: box, devicePixelRatio: 2),
      );
      return (resolved.width, resolved.height);
    }

    test('a square box', () async {
      // 100 at 2x rounds up to 256; 256 * 1920 / 884 rounds up to 557.
      expect(await decode(const Size(100, 100), 884, 1920), (256, 557));
    });

    test('a tall box with a tall screenshot', () async {
      // 300 x 600 at 2x rounds up to 640 x 1216, and the width covers it.
      expect(await decode(const Size(300, 600), 884, 1920), (640, 1391));
      expect(await decode(const Size(300, 600), 1179, 2556), (640, 1388));
    });

    test('a wide box with a wide photo', () async {
      expect(await decode(const Size(600, 300), 1920, 884), (1391, 640));
    });

    test('a box larger than the image does not scale it up', () async {
      expect(await decode(const Size(300, 300), 200, 200), (200, 200));
    });

    test('the size after the EXIF rotation covers the box', () async {
      expect(
        await decode(const Size(300, 600), 1920, 884, orientation: 6),
        (640, 1391),
      );
    });

    test('the same box size has the same cache key', () async {
      final file = FileImage(File('photo.jpg'));
      Future<Object> key(Size box) => coverDecodeImage(
        file,
        box: box,
        devicePixelRatio: 2,
      ).obtainKey(ImageConfiguration.empty);
      expect(
        await key(const Size(300, 600)),
        await key(const Size(310, 605)),
      );
      expect(
        await key(const Size(300, 600)),
        isNot(await key(const Size(340, 600))),
      );
    });

    test('a box with no finite size keeps the image', () {
      final file = FileImage(File('photo.jpg'));
      expect(
        identical(
          coverDecodeImage(
            file,
            box: const Size(double.infinity, 100),
            devicePixelRatio: 2,
          ),
          file,
        ),
        isTrue,
      );
    });
  });

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

  testWidgets('checks a resized gif file before it shows', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NormalizedGifImageGate(
          image: CoverResizeImage(
            FileImage(
              File('resized_gate_test_${identityHashCode(tester)}.gif'),
            ),
            width: 10,
            height: 10,
          ),
          placeholder: () => const SizedBox(key: Key('placeholder')),
          childBuilder: () => const SizedBox(key: Key('child')),
        ),
      ),
    );

    expect(find.byKey(const Key('placeholder')), findsOneWidget);
  });

  testWidgets('a new decode size of a checked file keeps the child state', (
    tester,
  ) async {
    final file = File('resized_keep_test_${identityHashCode(tester)}.gif');
    var mounts = 0;
    Widget gate(int width) => Directionality(
      textDirection: TextDirection.ltr,
      child: NormalizedGifImageGate(
        image: CoverResizeImage(FileImage(file), width: width, height: width),
        placeholder: () => const SizedBox(key: Key('placeholder')),
        childBuilder: () => _MountCounter(onMount: () => mounts++),
      ),
    );

    await tester.pumpWidget(gate(10));
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        if (find.byType(_MountCounter).evaluate().isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    expect(find.byType(_MountCounter), findsOneWidget);
    expect(mounts, 1);

    await tester.pumpWidget(gate(20));
    expect(find.byType(_MountCounter), findsOneWidget);
    expect(mounts, 1);
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

  testWidgets('a replacement load keeps showing the image it replaces', (
    tester,
  ) async {
    final png = Uint8List.fromList(
      img.encodePng(img.Image(width: 4, height: 4)),
    );
    const placeholderKey = Key('placeholder');
    Widget pipeline(ImageProvider image) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaImagePipeline(
        image: image,
        gaplessPlayback: true,
        placeholder: () => const SizedBox(key: placeholderKey),
      ),
    );

    await tester.pumpWidget(pipeline(MemoryImage(png)));
    expect(find.byKey(placeholderKey), findsOneWidget);
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        if (find.byKey(placeholderKey).evaluate().isEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    });
    expect(find.byKey(placeholderKey), findsNothing);

    // A new decode size starts a load that has not finished.
    await tester.pumpWidget(pipeline(_PendingImage()));
    expect(find.byKey(placeholderKey), findsNothing);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });
}

Future<_ResolvedImage> _resolveImage(ImageProvider image) {
  final stream = image.resolve(ImageConfiguration.empty);
  final completer = Completer<_ResolvedImage>();
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, synchronouslyLoaded) {
      final width = image.image.width;
      final height = image.image.height;
      image.dispose();
      stream.removeListener(listener);
      completer.complete(
        _ResolvedImage(
          width: width,
          height: height,
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
    required this.height,
    required this.synchronouslyLoaded,
  });

  final int width;
  final int height;
  final bool synchronouslyLoaded;
}

class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

class _MountCounter extends StatefulWidget {
  const _MountCounter({required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountCounter> createState() => _MountCounterState();
}

class _MountCounterState extends State<_MountCounter> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
