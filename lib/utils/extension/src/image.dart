part of '../extension.dart';

extension ImageProviderExtension<T extends Object> on ImageProvider<T> {
  Future<ui.Image> toImage({
    ImageConfiguration configuration = ImageConfiguration.empty,
  }) {
    final completer = Completer<ui.Image>();
    late ImageStreamListener listener;
    final stream = resolve(configuration);
    listener = ImageStreamListener((ImageInfo frame, bool sync) {
      final image = frame.image;
      completer.complete(image);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return completer.future;
  }
}

extension ImageExtension on ui.Image {
  Future<Uint8List?> toBytes({
    ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba,
  }) async => (await toByteData(format: format))?.buffer.asUint8List();
}
