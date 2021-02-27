import 'dart:async';

import 'package:flutter/painting.dart';

Future<ImageInfo> getImageInfo(ImageProvider imageProvider) {
  final completer = Completer<ImageInfo>();
  final imageStream = imageProvider.resolve(const ImageConfiguration());
  late ImageStreamListener imageStreamListener;
  imageStreamListener =
      ImageStreamListener((ImageInfo image, bool synchronousCall) {
    completer.complete(image);
    imageStream.removeListener(imageStreamListener);
  });
  imageStream.addListener(imageStreamListener);
  return completer.future;
}
