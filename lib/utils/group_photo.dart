import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

// The same limit as the Android client.
const _maxGroupPhotoSize = 512;

/// Crops the image at [path] to a centered square of at most 512 px, and
/// encodes it as an unpadded base64url JPEG for `icon_base64`.
Future<String?> encodeGroupPhoto(String path) => Isolate.run(() {
  final image = img.decodeImage(File(path).readAsBytesSync());
  if (image == null) return null;
  final size = math.min(
    _maxGroupPhotoSize,
    math.min(image.width, image.height),
  );
  final jpg = img.encodeJpg(img.copyResizeCropSquare(image, size: size));
  return base64Url.encode(jpg).replaceAll('=', '');
});
