import 'dart:typed_data';

import 'package:image/image.dart';

import 'load_balancer_utils.dart';

const _kMaxDimension = 1920;
const _kQuality = 85;

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

  // Re-encoding are larger then original image.
  if (decoder is GifDecoder) {
    return (data, ImageType.gif, image.width, image.height);
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
