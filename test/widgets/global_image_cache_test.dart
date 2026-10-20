import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/utils/image.dart';
import 'package:flutter_app/utils/proxy.dart';
import 'package:flutter_app/widgets/global_image_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('uses the disk cache after recreation', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final fetcher = _ImageFetcher([
      _ResponseData(Uint8List.fromList([1, 2, 3]), maxAge: 1),
    ]);

    final first = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );
    expect(
      await first
          .getBytes('https://example.com/image.png', limitBytes: false)
          .single,
      [1, 2, 3],
    );

    final second = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );
    expect(
      await second
          .getBytes('https://example.com/image.png', limitBytes: false)
          .single,
      [1, 2, 3],
    );
    expect(fetcher.calls, 1);
  });

  test('does not persist no-store responses', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final fetcher = _ImageFetcher([
      _ResponseData(Uint8List.fromList([1]), maxAge: 0),
      _ResponseData(Uint8List.fromList([2]), maxAge: 0, noStore: true),
      _ResponseData(Uint8List.fromList([3]), maxAge: 1),
    ]);
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );

    expect(
      await cache
          .getBytes('https://example.com/image.png', limitBytes: false)
          .single,
      [1],
    );
    expect(
      await cache
          .getBytes('https://example.com/image.png', limitBytes: false)
          .toList(),
      [
        [1],
        [2],
      ],
    );

    final restarted = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );
    expect(
      await restarted
          .getBytes('https://example.com/image.png', limitBytes: false)
          .single,
      [3],
    );
    expect(fetcher.calls, 3);
  });

  test(
    'revalidates no-cache responses regardless of directive order',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'image-cache-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fetcher = _ImageFetcher([
        _ResponseData(
          Uint8List.fromList([1]),
          maxAge: 0,
          cacheControl: 'no-cache, max-age=3600',
          eTag: 'one',
        ),
        _ResponseData(Uint8List.fromList([2]), maxAge: 1),
      ]);
      final cache = GlobalImageCache.forTesting(
        directory: directory,
        fetcher: fetcher.call,
        maxSizeBytes: 1024,
      );

      expect(
        await cache
            .getBytes('https://example.com/image.png', limitBytes: false)
            .single,
        [1],
      );
      expect(
        await cache
            .getBytes('https://example.com/image.png', limitBytes: false)
            .toList(),
        [
          [1],
          [2],
        ],
      );
      expect(fetcher.headers.last[HttpHeaders.ifNoneMatchHeader], 'one');
    },
  );

  test(
    'keeps no-cache revalidation after a 304 without cache control',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'image-cache-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fetcher = _ImageFetcher([
        _ResponseData(
          Uint8List.fromList([1]),
          maxAge: 0,
          cacheControl: 'no-cache, max-age=3600',
          eTag: 'one',
        ),
        _ResponseData(
          Uint8List(0),
          maxAge: 0,
          statusCode: HttpStatus.notModified,
          omitCacheControl: true,
        ),
        _ResponseData(Uint8List.fromList([2]), maxAge: 1),
      ]);
      final cache = GlobalImageCache.forTesting(
        directory: directory,
        fetcher: fetcher.call,
        maxSizeBytes: 1024,
      );

      expect(
        await cache
            .getBytes('https://example.com/image.png', limitBytes: false)
            .single,
        [1],
      );
      expect(
        await cache
            .getBytes('https://example.com/image.png', limitBytes: false)
            .toList(),
        [
          [1],
        ],
      );
      expect(
        await cache
            .getBytes('https://example.com/image.png', limitBytes: false)
            .toList(),
        [
          [1],
          [2],
        ],
      );
      expect(fetcher.headers[1][HttpHeaders.ifNoneMatchHeader], 'one');
      expect(fetcher.headers[2][HttpHeaders.ifNoneMatchHeader], 'one');
    },
  );

  test('keeps proxy responses separate from direct responses', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final fetcher = _ImageFetcher([
      _ResponseData(Uint8List.fromList([1]), maxAge: 1),
      _ResponseData(Uint8List.fromList([2]), maxAge: 1),
    ]);
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );

    expect(
      await cache
          .getBytes('https://example.com/image.png', limitBytes: false)
          .single,
      [1],
    );
    expect(
      await cache
          .getBytes(
            'https://example.com/image.png',
            limitBytes: true,
            proxyConfig: ProxyConfig(
              type: ProxyType.http,
              host: '127.0.0.1',
              port: 8080,
              id: 'test',
            ),
          )
          .single,
      [2],
    );
    expect(fetcher.calls, 2);
  });

  test('emits a stale file before revalidating it', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final fetcher = _ImageFetcher([
      _ResponseData(Uint8List.fromList([1]), maxAge: 0, eTag: 'one'),
      _ResponseData(Uint8List.fromList([2]), maxAge: 1, eTag: 'two'),
    ]);
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );

    await cache
        .getBytes('https://example.com/image.png', limitBytes: false)
        .single;
    expect(
      await cache
          .getBytes('https://example.com/image.png', limitBytes: false)
          .toList(),
      [
        [1],
        [2],
      ],
    );
    expect(fetcher.calls, 2);
    expect(fetcher.headers.last[HttpHeaders.ifNoneMatchHeader], 'one');
  });

  test('keeps the image bytes when revalidation is unchanged', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final fetcher = _ImageFetcher([
      _ResponseData(Uint8List.fromList([1]), maxAge: 0),
      _ResponseData(Uint8List.fromList([1]), maxAge: 1),
    ]);
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 1024,
    );

    final original = await cache
        .getBytes('https://example.com/image.png', limitBytes: true)
        .single;
    expect(
      await cache
          .getBytes('https://example.com/image.png', limitBytes: true)
          .toList(),
      [
        [1],
      ],
    );
    expect(
      identical(
        original,
        await cache
            .getBytes('https://example.com/image.png', limitBytes: true)
            .single,
      ),
      isTrue,
    );
  });

  test('cancels failed response streams', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    var cancelled = false;
    final response = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: (_, _, _) async => http.StreamedResponse(
        response.stream,
        HttpStatus.internalServerError,
      ),
      maxSizeBytes: 1024,
    );

    await expectLater(
      cache
          .getBytes('https://example.com/image.png', limitBytes: false)
          .drain<void>(),
      throwsA(isA<HttpException>()),
    );
    expect(cancelled, isTrue);
  });

  test('rejects oversized responses before buffering', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    var cancelled = false;
    final response = StreamController<List<int>>(
      onCancel: () => cancelled = true,
    );
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: (_, _, _) async => http.StreamedResponse(
        response.stream,
        HttpStatus.ok,
        contentLength: maxDownloadedImageBytes + 1,
      ),
      maxSizeBytes: 1024,
    );

    await expectLater(
      cache
          .getBytes('https://example.com/image.png', limitBytes: true)
          .drain<void>(),
      throwsA(isA<StateError>()),
    );
    expect(cancelled, isTrue);
  });

  test('evicts the least recently used files over the byte limit', () async {
    final directory = await Directory.systemTemp.createTemp('image-cache-test');
    addTearDown(() => directory.delete(recursive: true));
    final fetcher = _ImageFetcher([
      _ResponseData(Uint8List.fromList([1, 1, 1, 1]), maxAge: 1),
      _ResponseData(Uint8List.fromList([2, 2, 2, 2]), maxAge: 1),
      _ResponseData(Uint8List.fromList([3, 3, 3, 3]), maxAge: 1),
      _ResponseData(Uint8List.fromList([4, 4, 4, 4]), maxAge: 1),
    ]);
    final cache = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 8,
    );

    await cache
        .getBytes('https://example.com/first.png', limitBytes: false)
        .single;
    await cache
        .getBytes('https://example.com/second.png', limitBytes: false)
        .single;
    await cache
        .getBytes('https://example.com/first.png', limitBytes: false)
        .single;

    final restarted = GlobalImageCache.forTesting(
      directory: directory,
      fetcher: fetcher.call,
      maxSizeBytes: 8,
    );
    await restarted
        .getBytes('https://example.com/third.png', limitBytes: false)
        .single;

    await restarted
        .getBytes('https://example.com/first.png', limitBytes: false)
        .single;
    expect(fetcher.calls, 3);
    await restarted
        .getBytes('https://example.com/second.png', limitBytes: false)
        .single;
    expect(fetcher.calls, 4);
  });
}

class _ImageFetcher {
  _ImageFetcher(this._responses);

  final List<_ResponseData> _responses;
  final headers = <Map<String, String>>[];
  int calls = 0;

  Future<http.StreamedResponse> call(
    Uri uri,
    ProxyConfig? proxyConfig,
    Map<String, String> requestHeaders,
  ) async {
    calls++;
    headers.add(requestHeaders);
    final response = _responses.removeAt(0);
    return http.StreamedResponse(
      Stream.value(response.bytes),
      response.statusCode,
      headers: {
        if (!response.omitCacheControl)
          HttpHeaders.cacheControlHeader:
              response.cacheControl ??
              (response.noStore ? 'no-store' : 'max-age=${response.maxAge}'),
        if (response.eTag != null) HttpHeaders.etagHeader: response.eTag!,
      },
    );
  }
}

class _ResponseData {
  const _ResponseData(
    this.bytes, {
    required this.maxAge,
    this.eTag,
    this.noStore = false,
    this.cacheControl,
    this.statusCode = HttpStatus.ok,
    this.omitCacheControl = false,
  });

  final Uint8List bytes;
  final int maxAge;
  final String? eTag;
  final bool noStore;
  final String? cacheControl;
  final int statusCode;
  final bool omitCacheControl;
}
