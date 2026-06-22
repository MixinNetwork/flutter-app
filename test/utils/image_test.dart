import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_app/utils/image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('downloadImageFile rejects oversized streaming responses', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final subscription = server.listen((request) async {
      request.response.add([1, 2]);
      request.response.add([3, 4]);
      await request.response.close();
    });
    addTearDown(subscription.cancel);

    await expectLater(
      downloadImageFile(
        'http://${server.address.host}:${server.port}',
        maxBytes: 3,
      ),
      throwsStateError,
    );
  });

  test('downloadImageBytes rejects oversized streaming responses', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final subscription = server.listen((request) async {
      request.response.add([1, 2]);
      request.response.add([3, 4]);
      await request.response.close();
    });
    addTearDown(subscription.cancel);

    await expectLater(
      downloadImageBytes(
        'http://${server.address.host}:${server.port}',
        maxBytes: 3,
      ),
      throwsStateError,
    );
  });

  test('compressImage normalizes short animated GIF frame durations', () {
    final encoded = _gifWithFrameDurations(10, 50);
    final result = compressImage(encoded);

    expect(result, isNotNull);

    final (bytes, type, _, _) = result!;
    final decoded = img.decodeGif(bytes);

    expect(type, ImageType.gif);
    expect(decoded, isNotNull);
    expect(decoded!.frames.map((frame) => frame.frameDuration), [100, 50]);
  });

  test('normalizeGifFrameDurations keeps normal animated GIF bytes', () {
    final encoded = _gifWithFrameDurations(20, 50);

    final normalized = normalizeGifFrameDurations(encoded);

    expect(identical(normalized, encoded), isTrue);
  });

  test('normalizeGifBytesIfNeeded normalizes GIF bytes', () {
    final encoded = _gifWithFrameDurations(10, 50);

    final normalized = normalizeGifBytesIfNeeded(encoded);
    final decoded = img.decodeGif(normalized);

    expect(decoded, isNotNull);
    expect(decoded!.frames.map((frame) => frame.frameDuration), [100, 50]);
  });

  test('normalizeGifBytesIfNeeded keeps non-GIF bytes', () {
    final encoded = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);

    final normalized = normalizeGifBytesIfNeeded(encoded);

    expect(identical(normalized, encoded), isTrue);
  });

  test('normalizeGifFileIfNeeded rewrites cached GIF files', () async {
    final file = File(
      '${Directory.systemTemp.path}/mixin-gif-${DateTime.now().microsecondsSinceEpoch}.gif',
    );
    await file.writeAsBytes(_gifWithFrameDurations(10, 50));

    try {
      await normalizeGifFileIfNeeded(file, ImageType.gif.mimeType);

      final decoded = img.decodeGif(await file.readAsBytes());

      expect(decoded, isNotNull);
      expect(decoded!.frames.map((frame) => frame.frameDuration), [100, 50]);
    } finally {
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  });

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

Uint8List _gifWithFrameDurations(int firstFrameMs, int secondFrameMs) {
  final first = img.Image(width: 1, height: 1, numChannels: 4)
    ..setPixelRgba(0, 0, 0, 0, 0, 255)
    ..frameDuration = firstFrameMs;
  final second = img.Image(width: 1, height: 1, numChannels: 4)
    ..setPixelRgba(0, 0, 255, 255, 255, 255)
    ..frameDuration = secondFrameMs;
  first.addFrame(second);
  return img.encodeGif(first);
}
