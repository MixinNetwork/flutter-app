import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart';

import 'file.dart';
import 'load_balancer_utils.dart';
import 'proxy.dart';

const _kMaxDimension = 1920;
const _kQuality = 85;
const _kMinGifFrameDelayCentiseconds = 2;
const _kDefaultGifFrameDelayCentiseconds = 10;
// ponytail: remote images above this are too risky to decode in memory.
const _kMaxDownloadedImageBytes = 32 * 1024 * 1024;

enum ImageType { gif, jpeg, png }

extension ImageTypeExtension on ImageType {
  String get mimeType => switch (this) {
    ImageType.gif => 'image/gif',
    ImageType.jpeg => 'image/jpeg',
    ImageType.png => 'image/png',
  };

  String get extension => switch (this) {
    ImageType.gif => 'gif',
    ImageType.jpeg => 'jpg',
    ImageType.png => 'png',
  };
}

(Uint8List, ImageType, int, int)? compressImage(Uint8List data) {
  final decoder = findDecoderForData(data);

  var image = decoder?.decode(data);
  if (image == null) return null;

  if (decoder is GifDecoder) {
    return (
      normalizeGifFrameDurations(data),
      ImageType.gif,
      image.width,
      image.height,
    );
  }

  if (image.width > _kMaxDimension || image.height > _kMaxDimension) {
    final aspectRatio = image.width / image.height;
    int targetWidth;
    int targetHeight;

    if (aspectRatio < 1 / 3) {
      targetHeight = image.height;
      targetWidth = image.width;
    } else if (aspectRatio > 1) {
      // landscape
      targetWidth = _kMaxDimension;
      targetHeight = (targetWidth / aspectRatio).round();
    } else {
      // portrait or square
      targetHeight = _kMaxDimension;
      targetWidth = (targetHeight * aspectRatio).round();
    }

    image = copyResize(image, width: targetWidth, height: targetHeight);
  }

  final maxChannelValue = image.maxChannelValue;
  final hasTransparency = image.any((pixel) => pixel.a < maxChannelValue);

  if (hasTransparency) {
    return (
      Uint8List.fromList(encodePng(image)),
      ImageType.png,
      image.width,
      image.height,
    );
  }

  return (
    JpegEncoder(quality: _kQuality).encode(image),
    ImageType.jpeg,
    image.width,
    image.height,
  );
}

Future<(Uint8List, ImageType, int, int)?> compressWithIsolate(Uint8List data) =>
    runLoadBalancer(compressImage, data);

Future<(Uint8List, ImageType, int, int)?> compressFileWithIsolate(File file) =>
    runLoadBalancer((path) {
      final data = File(path).readAsBytesSync();
      return compressImage(data);
    }, file.path);

Future<File?> downloadImageFile(
  String url, {
  ProxyConfig? proxyConfig,
  int maxBytes = _kMaxDownloadedImageBytes,
}) async {
  final resolved = Uri.base.resolve(url);
  final client = await createRHttpClient(proxyConfig: proxyConfig);
  final response = await client.send(http.Request('GET', resolved));
  if (response.statusCode != HttpStatus.ok) return null;

  final contentLength = response.contentLength;
  if (contentLength != null && contentLength > maxBytes) {
    throw StateError('NetworkImage is too large: $resolved');
  }

  final file = File(await generateTempFilePath(TempFileType.networkImage));
  final sink = file.openWrite();
  var received = 0;
  try {
    await for (final chunk in response.stream) {
      received += chunk.length;
      if (received > maxBytes) {
        throw StateError('NetworkImage is too large: $resolved');
      }
      sink.add(chunk);
    }
    await sink.close();
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {}
    if (file.existsSync()) await file.delete();
    rethrow;
  }

  if (received == 0) {
    await file.delete();
    throw StateError('NetworkImage is an empty file: $resolved');
  }

  return file;
}

Uint8List normalizeGifBytesIfNeeded(Uint8List data) {
  if (!_isGifBytes(data)) return data;
  return normalizeGifFrameDurations(data);
}

Uint8List normalizeGifFrameDurations(Uint8List data) {
  if (!_isGifBytes(data)) return data;

  Uint8List? normalized;
  for (var index = 0; index <= data.length - 8; index++) {
    if (data[index] != 0x21 ||
        data[index + 1] != 0xF9 ||
        data[index + 2] != 0x04 ||
        data[index + 7] != 0x00) {
      continue;
    }

    final delay = data[index + 4] | (data[index + 5] << 8);
    if (delay >= _kMinGifFrameDelayCentiseconds) continue;

    normalized ??= Uint8List.fromList(data);
    normalized[index + 4] = _kDefaultGifFrameDelayCentiseconds;
    normalized[index + 5] = 0;
  }

  return normalized ?? data;
}

Future<void> normalizeGifFileIfNeeded(File file, String? mimeType) async {
  if (mimeType?.toLowerCase() != ImageType.gif.mimeType) return;
  if (!file.existsSync()) return;

  final data = await file.readAsBytes();
  final normalized = normalizeGifFrameDurations(data);
  if (!identical(normalized, data)) {
    await file.writeAsBytes(normalized, flush: true);
  }
}

bool _isGifBytes(Uint8List data) =>
    data.length >= 6 &&
    data[0] == 0x47 &&
    data[1] == 0x49 &&
    data[2] == 0x46 &&
    data[3] == 0x38 &&
    (data[4] == 0x37 || data[4] == 0x39) &&
    data[5] == 0x61;
